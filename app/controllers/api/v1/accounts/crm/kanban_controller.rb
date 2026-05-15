class Api::V1::Accounts::Crm::KanbanController < Api::V1::Accounts::BaseController
  PIPELINE_TEMPLATES = {
    'sales' => [
      { name: 'Novos leads', color: 'blue', stale_after_days: 2, win_probability: 10 },
      { name: 'Qualificacao', color: 'teal', stale_after_days: 3, win_probability: 25 },
      { name: 'Proposta enviada', color: 'amber', stale_after_days: 4, win_probability: 55 },
      { name: 'Negociacao', color: 'ruby', stale_after_days: 3, win_probability: 75 },
      { name: 'Ganhou', color: 'green', stale_after_days: 0, win_probability: 100 },
      { name: 'Perdido', color: 'slate', stale_after_days: 0, win_probability: 0 }
    ].freeze,
    'support' => [
      { name: 'Novas conversas', color: 'ruby', stale_after_days: 1, win_probability: 10 },
      { name: 'Nao lidas', color: 'amber', stale_after_days: 1, win_probability: 25 },
      { name: 'Lidas', color: 'blue', stale_after_days: 2, win_probability: 50 },
      { name: 'Respondida', color: 'teal', stale_after_days: 2, win_probability: 80 }
    ].freeze,
    'delayed_conversations' => [
      { name: 'Novas Conversas', color: 'ruby', stale_after_days: 1, win_probability: 10 },
      { name: 'Nao Lidas', color: 'amber', stale_after_days: 1, win_probability: 25 },
      { name: 'Lidas', color: 'blue', stale_after_days: 2, win_probability: 50 },
      { name: 'Respondida', color: 'teal', stale_after_days: 2, win_probability: 80 }
    ].freeze,
    'recovery' => [
      { name: 'Contatar ASAP', color: 'amber', stale_after_days: 1, win_probability: 20 },
      { name: 'Coleta de informacoes', color: 'violet', stale_after_days: 3, win_probability: 40 },
      { name: 'Tratativas criticas', color: 'ruby', stale_after_days: 2, win_probability: 60 },
      { name: 'Informacoes finais', color: 'teal', stale_after_days: 4, win_probability: 85 }
    ].freeze,
    'onboarding' => [
      { name: 'Novo cliente', color: 'blue', stale_after_days: 2, win_probability: 20 },
      { name: 'Setup', color: 'violet', stale_after_days: 3, win_probability: 45 },
      { name: 'Treinamento', color: 'teal', stale_after_days: 5, win_probability: 70 },
      { name: 'Ativo', color: 'green', stale_after_days: 0, win_probability: 100 }
    ].freeze
  }.freeze

  before_action :pipeline

  def show
    render json: board_payload
  end

  def update
    pipeline.update!(pipeline_params)
    render json: board_payload
  end

  def create_pipeline
    record = Current.account.crm_kanban_pipelines.create!(
      pipeline_params.merge(
        default: false,
        position: Current.account.crm_kanban_pipelines.maximum(:position).to_i + 1
      )
    )
    apply_pipeline_template!(record, params.dig(:pipeline, :template))
    @pipeline = record
    render json: board_payload, status: :created
  end

  def update_pipeline
    record = fetch_pipeline(params[:pipeline_id])
    record.update!(pipeline_params)
    @pipeline = record
    render json: board_payload
  end

  def destroy_pipeline
    record = fetch_pipeline(params[:pipeline_id])
    return render_error('O funil padrao nao pode ser excluido.') if record.default?
    return render_error('Arquive ou mova os cards antes de excluir este funil.') if record.cards.exists?

    record.destroy!
    @pipeline = Crm::KanbanPipeline.ensure_default_for!(Current.account)
    render json: board_payload
  end

  def create_card
    stage = fetch_stage(params.dig(:card, :stage_id))
    card = Current.account.crm_kanban_cards.create!(
      card_params.merge(
        pipeline: pipeline,
        stage: stage,
        position: next_card_position(stage),
        stage_changed_at: Time.current,
        last_activity_at: Time.current
      )
    )

    record_action(card, 'card.created')
    dispatch_webhook(card, 'card.created')
    render json: card_payload(card), status: :created
  end

  def update_card
    card = fetch_card
    attributes = card_params.to_h
    attributes.delete('contact_id') if card.contact_id.present?
    attributes.delete('conversation_id') if card.conversation_id.present?
    previous_stage_id = card.stage_id
    previous_pipeline_id = card.pipeline_id
    previous_follow_up_mode = card.metadata.to_h.dig('follow_up_override', 'mode')

    if attributes['stage_id'].present? && attributes['stage_id'].to_i != card.stage_id
      stage = fetch_stage(attributes.delete('stage_id'))
      attributes['stage'] = stage
      attributes['stage_changed_at'] = Time.current
      attributes['status'] = status_for_stage(stage) if attributes['status'].blank?
    end

    attributes['last_activity_at'] = Time.current if card_activity_update?(attributes)
    card.update!(attributes)
    cancel_follow_ups_for_closed_card(card) unless card.status == 'open'
    cancel_follow_ups_for_paused_card(card)
    cancel_follow_ups_for_removed_manual_override(card, previous_follow_up_mode)
    Crm::Kanban::FollowUps::PipelineTransitionService.new(
      card: card,
      previous_pipeline_id: previous_pipeline_id
    ).perform
    action_type = previous_stage_id == card.stage_id ? 'card.updated' : 'card.moved'
    record_action(card, action_type, data: { from_stage_id: previous_stage_id, to_stage_id: card.stage_id })
    dispatch_webhook(card, action_type, data: { from_stage_id: previous_stage_id, to_stage_id: card.stage_id })
    render json: card_payload(card.reload)
  end

  def destroy_card
    card = fetch_card
    card.update!(status: 'archived', last_activity_at: Time.current)
    cancel_follow_ups_for_closed_card(card)
    record_action(card, 'card.archived')
    dispatch_webhook(card, 'card.archived')
    head :ok
  end

  def summarize_card
    card = fetch_card
    return render_error('Vincule uma conversa salva para gerar o resumo.') if card.conversation.blank?

    result = Captain::KanbanSummaryService.new(
      account: Current.account,
      conversation_display_id: card.conversation.display_id
    ).perform

    return render json: { error: result[:error] }, status: :unprocessable_content if result[:error]

    render json: { message: result[:message] }
  end

  def create_follow_up
    card = fetch_card
    schedule = Crm::Kanban::FollowUps::ManualScheduler.new(
      card: card,
      scheduled_for: follow_up_params[:scheduled_for],
      instruction: follow_up_params[:message_instruction]
    ).perform

    render json: follow_up_payload(schedule), status: :created
  end

  def update_follow_up
    card = fetch_card
    schedule = card.follow_up_schedules.find(params[:follow_up_id])
    schedule.update!(
      generated_message: follow_up_review_params[:generated_message],
      metadata: schedule.metadata.to_h.merge(
        'review_state' => follow_up_review_params[:review_state]
      )
    )

    render json: follow_up_payload(schedule.reload)
  end

  def cancel_follow_up
    card = fetch_card
    schedule = card.follow_up_schedules.find(params[:follow_up_id])
    schedule.cancel!(reason: 'review_canceled')
    render json: follow_up_payload(schedule.reload)
  end

  def update_stage
    stage = fetch_stage(params[:stage_id])
    stage.update!(stage_params)
    render json: stage_payload(stage.reload)
  end

  def create_stage
    stage = pipeline.stages.create!(
      stage_params.merge(
        account: Current.account,
        position: pipeline.stages.maximum(:position).to_i + 1
      )
    )
    render json: stage_payload(stage), status: :created
  end

  def destroy_stage
    stage = fetch_stage(params[:stage_id])
    return render_error('O funil precisa ter pelo menos uma etapa.') if pipeline.stages.count <= 1
    return render_error('Mova ou arquive os cards antes de excluir esta etapa.') if stage.cards.exists?

    stage.destroy!
    normalize_stage_positions!
    head :ok
  end

  def create_activity
    card = fetch_card
    activity = card.activities.create!(activity_params.merge(account: Current.account))
    record_action(card, 'activity.created', data: { activity_id: activity.id })
    dispatch_webhook(card, 'activity.created', data: { activity_id: activity.id })
    render json: activity_payload(activity), status: :created
  end

  def update_activity
    card = fetch_card
    activity = fetch_activity(card)
    activity.update!(activity_params)
    record_action(card, 'activity.updated', data: { activity_id: activity.id })
    dispatch_webhook(card, 'activity.updated', data: { activity_id: activity.id })
    render json: activity_payload(activity.reload)
  end

  def complete_activity
    card = fetch_card
    activity = fetch_activity(card)
    activity.complete!
    record_action(card, 'activity.completed', data: { activity_id: activity.id })
    dispatch_webhook(card, 'activity.completed', data: { activity_id: activity.id })
    render json: activity_payload(activity.reload)
  end

  def create_webhook
    webhook = Current.account.crm_kanban_webhooks.create!(webhook_params.merge(pipeline: pipeline))
    render json: webhook_payload(webhook), status: :created
  end

  def update_webhook
    webhook = fetch_webhook
    webhook.update!(webhook_params)
    render json: webhook_payload(webhook.reload)
  end

  def destroy_webhook
    fetch_webhook.destroy!
    head :ok
  end

  private

  def pipeline
    @pipeline ||= begin
      default_pipeline = Crm::KanbanPipeline.ensure_default_for!(Current.account)
      params[:pipeline_id].present? ? fetch_pipeline(params[:pipeline_id]) : default_pipeline
    end
  end

  def fetch_pipeline(pipeline_id)
    Current.account.crm_kanban_pipelines.find(pipeline_id)
  end

  def fetch_stage(stage_id)
    return pipeline.stages.order(:position).first if stage_id.blank?

    Current.account.crm_kanban_stages.where(pipeline: pipeline).find(stage_id)
  end

  def fetch_card
    Current.account.crm_kanban_cards.where(pipeline: pipeline).find(params[:card_id])
  end

  def fetch_activity(card)
    card.activities.find(params[:activity_id])
  end

  def fetch_webhook
    visible_webhooks.find(params[:webhook_id])
  end

  def next_card_position(stage)
    stage.cards.maximum(:position).to_i + 1
  end

  def card_activity_update?(attributes)
    attributes.keys.intersect?(
      %w[summary notes budget_amount budget_currency contact_id conversation_id product_id assignee_id status next_activity_at]
    )
  end

  def status_for_stage(stage)
    return 'won' if stage.name.downcase.include?('ganhou')
    return 'lost' if stage.name.downcase.include?('perdido')

    'open'
  end

  def pipeline_params
    permitted = params.require(:pipeline).permit(:name, :description, :ai_rules)
    permitted[:settings] = params[:pipeline][:settings].permit!.to_h if params[:pipeline][:settings].present?
    permitted
  end

  def stage_params
    params.require(:stage).permit(:name, :color, :position, :stale_after_days, :win_probability, settings: {})
  end

  def card_params
    params.require(:card).permit(
      :title, :stage_id, :contact_id, :conversation_id, :product_id, :assignee_id,
      :budget_amount, :budget_currency, :summary, :notes, :status, :position,
      :next_activity_at, :lost_reason,
      metadata: {}
    )
  end

  def activity_params
    params.require(:activity).permit(
      :title, :description, :activity_type, :status, :due_at, :completed_at, :assignee_id,
      metadata: {}
    )
  end

  def webhook_params
    params.require(:webhook).permit(:name, :url, :access_token, :active, events: [])
  end

  def follow_up_params
    params.require(:follow_up).permit(:scheduled_for, :message_instruction)
  end

  def follow_up_review_params
    params.require(:follow_up).permit(:generated_message, :review_state)
  end

  def normalize_stage_positions!
    pipeline.stages.order(:position, :id).each_with_index do |stage, index|
      stage.update_column(:position, index) if stage.position != index
    end
  end

  def render_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def board_payload
    cards = pipeline.cards
                    .active
                    .includes(:contact, :product, :assignee, :stage, :last_message, conversation: { applied_sla: :sla_policy })
                    .ordered

    {
      pipeline: pipeline_payload(pipeline),
      pipelines: Current.account.crm_kanban_pipelines.order(:position, :id).map { |record| pipeline_payload(record) },
      stages: pipeline.stages.order(:position).map { |stage| stage_payload(stage) },
      cards: cards.map { |card| card_payload(card) },
      webhooks: visible_webhooks.order(:created_at).map { |webhook| webhook_payload(webhook) },
      metrics: metrics_payload(cards)
    }
  end

  def visible_webhooks
    scoped = Current.account.crm_kanban_webhooks
    scoped.where(pipeline: pipeline).or(scoped.where(pipeline_id: nil))
  end

  def apply_pipeline_template!(record, template)
    stages = PIPELINE_TEMPLATES[template.presence] || Crm::KanbanPipeline::DEFAULT_STAGES

    record.stages.destroy_all
    stages.each_with_index do |stage_attributes, index|
      record.stages.create!(
        stage_attributes.merge(account: Current.account, position: index)
      )
    end
    apply_automation_template!(record, template)
  end

  def apply_automation_template!(record, template)
    return unless template == 'delayed_conversations'

    stage_by_name = record.stages.index_by(&:name)
    record.update!(
      settings: record.settings.to_h.merge(
        'automation_rules' => [
          automation_rule('Respondida', 'agent_replied', stage_by_name['Respondida']),
          automation_rule('Nao lidas', 'unread', stage_by_name['Nao Lidas']),
          automation_rule('Lidas aguardando resposta', 'waiting_reply', stage_by_name['Lidas']),
          automation_rule('Novas conversas', 'incoming_message', stage_by_name['Novas Conversas'])
        ].compact
      )
    )
  end

  def automation_rule(name, condition, stage)
    return if stage.blank?

    {
      id: "template-#{condition}",
      name: name,
      enabled: true,
      trigger: 'message_created',
      condition: condition,
      stage_id: stage.id
    }
  end

  def pipeline_payload(record)
    record.as_json(only: [:id, :name, :description, :ai_rules, :default, :position, :settings, :created_at, :updated_at])
  end

  def stage_payload(stage)
    stage.as_json(only: [:id, :name, :color, :position, :stale_after_days, :win_probability, :settings])
  end

  def card_payload(card)
    card.as_json(
      only: [
        :id, :pipeline_id, :stage_id, :contact_id, :conversation_id, :product_id, :assignee_id,
        :title, :budget_amount, :budget_currency, :summary, :notes, :status, :source,
        :position, :stage_changed_at, :last_activity_at, :next_activity_at, :auto_created,
        :won_at, :lost_at, :lost_reason, :metadata, :created_at, :updated_at
      ]
    ).merge(
      stale_days: card.stale_days,
      stale_level: card.stale_level,
      urgency: card_urgency_payload(card),
      contact: contact_payload(card.contact),
      conversation: conversation_payload(card.conversation),
      product: product_payload(card.product),
      assignee: user_payload(card.assignee),
      last_message: message_payload(card.last_message),
      next_follow_up: follow_up_payload(next_follow_up_for(card)),
      activities: card.activities.ordered.limit(20).map { |activity| activity_payload(activity) },
      actions: card.actions.order(created_at: :desc).limit(12).map { |action| action_payload(action) }
    )
  end

  def metrics_payload(cards)
    card_ids = cards.map(&:id)
    urgency_payloads = cards.map { |card| card_urgency_payload(card) }
    open_activities = Crm::KanbanActivity.open_status.where(account: Current.account, card_id: card_ids)

    {
      total_cards: cards.size,
      open_cards: cards.count { |card| card.status == 'open' },
      stale_cards: cards.count { |card| %w[stale critical].include?(card.stale_level) },
      sla_missed_cards: urgency_payloads.count { |urgency| urgency[:source] == 'chatwoot_sla' && urgency[:level] == 'critical' },
      budget_total: cards.select { |card| card.status == 'open' }.sum { |card| card.budget_amount.to_f },
      overdue_activities: open_activities.where('due_at < ?', Time.current).count,
      due_today: open_activities.where(due_at: Time.current.all_day).count
    }
  end

  def contact_payload(contact)
    return nil if contact.blank?

    contact.as_json(
      only: [:id, :name, :email, :phone_number, :identifier, :custom_attributes, :additional_attributes, :last_activity_at]
    )
  end

  def conversation_payload(conversation)
    return nil if conversation.blank?

    conversation.as_json(only: [:id, :display_id, :status, :inbox_id, :last_activity_at]).merge(
      applied_sla: applied_sla_payload(conversation.applied_sla)
    )
  end

  def card_urgency_payload(card)
    native_sla = native_sla_urgency_payload(card.conversation)
    return native_sla if native_sla.present?

    kanban_stage_urgency_payload(card)
  end

  def native_sla_urgency_payload(conversation)
    return nil if conversation.blank? || conversation.applied_sla.blank?

    applied_sla = conversation.applied_sla
    policy = applied_sla.sla_policy
    threshold = current_sla_threshold(conversation, policy)
    level = applied_sla_missed?(applied_sla) ? 'critical' : threshold_level(threshold&.dig(:due_at))

    {
      source: 'chatwoot_sla',
      type: threshold&.dig(:type),
      level: level,
      label: sla_urgency_label(applied_sla, threshold, level),
      due_at: threshold&.dig(:due_at)&.iso8601,
      policy_name: policy&.name,
      status: applied_sla.sla_status
    }
  end

  def kanban_stage_urgency_payload(card)
    {
      source: 'kanban_stage',
      type: 'stage_stale',
      level: card.stale_level,
      label: kanban_urgency_label(card),
      due_at: kanban_stage_due_at(card)&.iso8601
    }
  end

  def current_sla_threshold(conversation, policy)
    return nil if policy.blank?

    if conversation.first_reply_created_at.blank? && policy.first_response_time_threshold.present?
      return sla_threshold('FRT', conversation.created_at, policy.first_response_time_threshold)
    end

    if conversation.first_reply_created_at.present? &&
       conversation.waiting_since.present? &&
       policy.next_response_time_threshold.present?
      return sla_threshold('NRT', conversation.waiting_since, policy.next_response_time_threshold)
    end

    return nil if conversation.resolved? || policy.resolution_time_threshold.blank?

    sla_threshold('RT', conversation.created_at, policy.resolution_time_threshold)
  end

  def sla_threshold(type, starts_at, threshold)
    return nil if starts_at.blank? || threshold.blank?

    { type: type, due_at: starts_at + threshold.to_i.seconds }
  end

  def threshold_level(due_at)
    return 'fresh' if due_at.blank?
    return 'critical' if due_at.past?
    return 'stale' if due_at <= 1.hour.from_now

    'fresh'
  end

  def applied_sla_missed?(applied_sla)
    applied_sla.missed? || applied_sla.active_with_misses?
  end

  def sla_urgency_label(applied_sla, threshold, level)
    type = threshold&.dig(:type) || 'SLA'
    return "#{type} vencido" if applied_sla_missed?(applied_sla) || level == 'critical'
    return "#{type} em risco" if level == 'stale'

    "#{type} em dia"
  end

  def kanban_urgency_label(card)
    return "#{card.stale_days}d parado" if card.stale_level == 'critical'
    return "#{card.stale_days}d sem avanco" if card.stale_level == 'stale'

    'Em dia'
  end

  def kanban_stage_due_at(card)
    return nil if card.stage_changed_at.blank? || card.stage.stale_after_days.to_i.zero?

    card.stage_changed_at + card.stage.stale_after_days.days
  end

  def applied_sla_payload(applied_sla)
    return nil if applied_sla.blank?

    {
      id: applied_sla.id,
      sla_policy_id: applied_sla.sla_policy_id,
      sla_status: applied_sla.sla_status,
      sla_name: applied_sla.sla_policy&.name
    }
  end

  def product_payload(product)
    return nil if product.blank?

    product.as_json(
      only: [
        :id, :name, :price, :currency, :availability_status, :track_inventory,
        :stock_quantity, :reserved_quantity, :low_stock_threshold
      ]
    ).merge(
      available_quantity: product.available_quantity,
      low_stock: product.low_stock?,
      sale_available: product.sale_available?
    )
  end

  def user_payload(user)
    return nil if user.blank?

    user.as_json(only: [:id, :name, :email])
  end

  def message_payload(message)
    return nil if message.blank?

    message.as_json(only: [:id, :content, :message_type, :content_type, :created_at])
  end

  def activity_payload(activity)
    activity.as_json(
      only: [
        :id, :card_id, :title, :description, :activity_type, :status, :due_at,
        :completed_at, :assignee_id, :metadata, :created_at, :updated_at
      ]
    ).merge(assignee: user_payload(activity.assignee))
  end

  def action_payload(action)
    action.as_json(only: [:id, :action_type, :actor_type, :data, :created_at]).merge(user: user_payload(action.user))
  end

  def webhook_payload(webhook)
    webhook.as_json(only: [:id, :pipeline_id, :name, :url, :events, :active, :created_at, :updated_at])
  end

  def next_follow_up_for(card)
    card.follow_up_schedules.scheduled.order(:scheduled_for, :id).first
  end

  def follow_up_payload(schedule)
    return nil if schedule.blank?

    schedule.as_json(
      only: [
        :id, :source, :status, :scheduled_for, :attempt_number, :cadence_step,
        :channel_type, :reason, :generated_message, :metadata
      ]
    )
  end

  def cancel_follow_ups_for_closed_card(card)
    Crm::Kanban::FollowUps::ScheduleCanceler.new(
      card: card,
      reason: "card_#{card.status}"
    ).perform
  end

  def cancel_follow_ups_for_paused_card(card)
    return unless card.metadata.to_h.dig('follow_up_override', 'mode') == 'paused'

    Crm::Kanban::FollowUps::ScheduleCanceler.new(
      card: card,
      reason: 'card_follow_up_paused'
    ).perform
  end

  def cancel_follow_ups_for_removed_manual_override(card, previous_follow_up_mode)
    return unless previous_follow_up_mode == 'manual'
    return unless card.metadata.to_h.dig('follow_up_override', 'mode') == 'inherit'

    Crm::Kanban::FollowUps::ScheduleCanceler.new(
      card: card,
      reason: 'card_follow_up_manual_override_removed'
    ).perform
  end

  def record_action(card, action_type, data: {})
    Crm::Kanban::ActionRecorder.new(card: card, action_type: action_type, user: Current.user, data: data).perform
  end

  def dispatch_webhook(card, event_name, data: {})
    Crm::Kanban::WebhookDispatcher.new(card: card, event_name: event_name, payload: data).perform
  end
end
