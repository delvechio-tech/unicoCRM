class Api::V1::Accounts::Crm::KanbanController < Api::V1::Accounts::BaseController
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
    record.ensure_default_stages!
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
    previous_stage_id = card.stage_id

    if attributes['stage_id'].present? && attributes['stage_id'].to_i != card.stage_id
      stage = fetch_stage(attributes.delete('stage_id'))
      attributes['stage'] = stage
      attributes['stage_changed_at'] = Time.current
      attributes['status'] = status_for_stage(stage) if attributes['status'].blank?
    end

    attributes['last_activity_at'] = Time.current if card_activity_update?(attributes)
    card.update!(attributes)
    action_type = previous_stage_id == card.stage_id ? 'card.updated' : 'card.moved'
    record_action(card, action_type, data: { from_stage_id: previous_stage_id, to_stage_id: card.stage_id })
    dispatch_webhook(card, action_type, data: { from_stage_id: previous_stage_id, to_stage_id: card.stage_id })
    render json: card_payload(card.reload)
  end

  def destroy_card
    card = fetch_card
    card.update!(status: 'archived', last_activity_at: Time.current)
    record_action(card, 'card.archived')
    dispatch_webhook(card, 'card.archived')
    head :ok
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
    Current.account.crm_kanban_webhooks.find(params[:webhook_id])
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
    params.require(:pipeline).permit(:name, :description, :ai_rules, settings: {})
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
                    .includes(:contact, :conversation, :product, :assignee, :stage)
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
      contact: contact_payload(card.contact),
      conversation: conversation_payload(card.conversation),
      product: product_payload(card.product),
      assignee: user_payload(card.assignee),
      last_message: message_payload(card.last_message),
      activities: card.activities.ordered.limit(20).map { |activity| activity_payload(activity) },
      actions: card.actions.order(created_at: :desc).limit(12).map { |action| action_payload(action) }
    )
  end

  def metrics_payload(cards)
    {
      total_cards: cards.size,
      open_cards: cards.count { |card| card.status == 'open' },
      stale_cards: cards.count { |card| %w[stale critical].include?(card.stale_level) },
      budget_total: cards.select { |card| card.status == 'open' }.sum { |card| card.budget_amount.to_f },
      overdue_activities: Crm::KanbanActivity.open_status.where(account: Current.account).where('due_at < ?', Time.current).count,
      due_today: Crm::KanbanActivity.open_status.where(account: Current.account, due_at: Time.current.all_day).count
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

    conversation.as_json(only: [:id, :display_id, :status, :inbox_id, :last_activity_at])
  end

  def product_payload(product)
    return nil if product.blank?

    product.as_json(only: [:id, :name, :price, :currency])
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

  def record_action(card, action_type, data: {})
    Crm::Kanban::ActionRecorder.new(card: card, action_type: action_type, user: Current.user, data: data).perform
  end

  def dispatch_webhook(card, event_name, data: {})
    Crm::Kanban::WebhookDispatcher.new(card: card, event_name: event_name, payload: data).perform
  end
end
