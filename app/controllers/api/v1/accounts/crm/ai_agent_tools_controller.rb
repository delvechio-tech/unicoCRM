class Api::V1::Accounts::Crm::AiAgentToolsController < Api::V1::Accounts::BaseController
  before_action :fetch_ai_agent

  def search_products
    render json: {
      query: search_params[:q].to_s,
      results: product_search.product_payloads
    }
  end

  def show_product
    product = @ai_agent.products.where(crm_products: { account_id: Current.account.id, active: true }).find(params[:product_id])

    render json: {
      result: Crm::AiAgents::ProductSearch.new(agent: @ai_agent, query: '').product_payload(product)
    }
  end

  def search_faqs
    render json: {
      query: search_params[:q].to_s,
      results: product_search.faq_payloads
    }
  end

  def search_kanban_cards
    query = search_params[:q].to_s.strip
    cards = kanban_pipeline.cards.active.includes(:stage, :contact, :conversation, :product).order(updated_at: :desc).limit(search_limit)
    cards = cards.where(kanban_search_clause, query: "%#{query}%") if query.present?

    render json: {
      query: query,
      ai_rules: kanban_pipeline.ai_rules,
      stages: kanban_pipeline.stages.order(:position).map { |stage| kanban_stage_payload(stage) },
      results: cards.map { |card| kanban_card_payload(card) }
    }
  end

  def update_kanban_card
    card = kanban_pipeline.cards.active.find(params[:card_id])
    attributes = kanban_card_params.to_h
    previous_stage_id = card.stage_id

    if attributes['stage_id'].present? && attributes['stage_id'].to_i != card.stage_id
      stage = kanban_pipeline.stages.find(attributes.delete('stage_id'))
      attributes['stage'] = stage
      attributes['stage_changed_at'] = Time.current
      attributes['status'] = status_for_stage(stage) if attributes['status'].blank?
    end

    card.update!(attributes.merge(source: 'ai_agent', last_activity_at: Time.current))
    action_type = previous_stage_id == card.stage_id ? 'card.updated' : 'card.moved'
    Crm::Kanban::ActionRecorder.new(
      card: card,
      action_type: action_type,
      actor_type: 'ai_agent',
      data: attributes.slice('status', 'budget_amount', 'summary', 'notes').merge(
        from_stage_id: previous_stage_id,
        to_stage_id: card.stage_id
      )
    ).perform
    Crm::Kanban::WebhookDispatcher.new(card: card, event_name: action_type, payload: { source: 'ai_agent' }).perform
    render json: { result: kanban_card_payload(card.reload) }
  end

  def create_kanban_activity
    card = kanban_pipeline.cards.active.find(params[:card_id])
    activity = card.activities.create!(kanban_activity_params.merge(account: Current.account, metadata: activity_metadata))

    Crm::Kanban::ActionRecorder.new(
      card: card,
      action_type: 'activity.created',
      actor_type: 'ai_agent',
      data: { activity_id: activity.id }
    ).perform
    Crm::Kanban::WebhookDispatcher.new(card: card, event_name: 'activity.created', payload: { activity_id: activity.id }).perform
    render json: { result: kanban_activity_payload(activity) }, status: :created
  end

  private

  def fetch_ai_agent
    @ai_agent = Current.account.crm_ai_agents.find(params[:ai_agent_id])
  end

  def product_search
    @product_search ||= Crm::AiAgents::ProductSearch.new(
      agent: @ai_agent,
      query: search_params[:q],
      limit: search_params[:limit]
    )
  end

  def search_params
    params.permit(:q, :limit)
  end

  def search_limit
    (search_params[:limit].presence || 10).to_i.clamp(1, 50)
  end

  def kanban_pipeline
    @kanban_pipeline ||= Crm::KanbanPipeline.ensure_default_for!(Current.account)
  end

  def kanban_card_params
    params.require(:card).permit(
      :stage_id, :title, :budget_amount, :budget_currency, :summary, :notes, :status, :next_activity_at, :lost_reason,
      metadata: {}
    )
  end

  def kanban_activity_params
    params.require(:activity).permit(:title, :description, :activity_type, :due_at, :assignee_id, metadata: {})
  end

  def activity_metadata
    kanban_activity_params[:metadata].to_h.merge('source' => 'ai_agent')
  end

  def kanban_search_clause
    [
      'crm_kanban_cards.title ILIKE :query',
      'crm_kanban_cards.summary ILIKE :query',
      'crm_kanban_cards.notes ILIKE :query'
    ].join(' OR ')
  end

  def status_for_stage(stage)
    return 'won' if stage.name.downcase.include?('ganhou')
    return 'lost' if stage.name.downcase.include?('perdido')

    'open'
  end

  def kanban_stage_payload(stage)
    stage.as_json(only: [:id, :name, :position, :stale_after_days, :win_probability])
  end

  def kanban_card_payload(card)
    {
      id: card.id,
      title: card.title,
      stage_id: card.stage_id,
      stage_name: card.stage.name,
      status: card.status,
      budget_amount: card.budget_amount,
      budget_currency: card.budget_currency,
      summary: card.summary,
      notes: card.notes,
      stale_days: card.stale_days,
      stale_level: card.stale_level,
      next_activity_at: card.next_activity_at,
      ai_rules: kanban_pipeline.ai_rules,
      product: product_payload(card.product),
      contact: card.contact&.as_json(only: [:id, :name, :email, :phone_number]),
      conversation: card.conversation&.as_json(only: [:id, :display_id, :status, :last_activity_at]),
      activities: card.activities.open_status.ordered.limit(5).map { |activity| kanban_activity_payload(activity) }
    }
  end

  def product_payload(product)
    return nil if product.blank?

    product.as_json(
      only: [
        :id, :name, :sku, :price, :currency, :availability_status, :track_inventory,
        :stock_quantity, :reserved_quantity, :low_stock_threshold
      ]
    ).merge(
      available_quantity: product.available_quantity,
      low_stock: product.low_stock?,
      sale_available: product.sale_available?
    )
  end

  def kanban_activity_payload(activity)
    activity.as_json(only: [:id, :title, :description, :activity_type, :status, :due_at, :completed_at, :metadata])
  end
end
