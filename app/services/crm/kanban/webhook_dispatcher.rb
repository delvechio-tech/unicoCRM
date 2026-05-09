class Crm::Kanban::WebhookDispatcher
  def initialize(card:, event_name:, payload: {})
    @card = card
    @event_name = event_name
    @payload = payload
  end

  def perform
    card.account.crm_kanban_webhooks.active.find_each do |webhook|
      next unless webhook.deliver?(event_name, card.pipeline_id)

      Crm::KanbanWebhookJob.perform_later(webhook.id, event_name, webhook_payload)
    end
  end

  private

  attr_reader :card, :event_name, :payload

  def webhook_payload
    {
      event: event_name,
      account_id: card.account_id,
      pipeline_id: card.pipeline_id,
      card_id: card.id,
      card: card_payload,
      data: payload,
      delivered_at: Time.current.iso8601
    }
  end

  def card_payload
    {
      id: card.id,
      title: card.title,
      status: card.status,
      stage_id: card.stage_id,
      contact_id: card.contact_id,
      conversation_id: card.conversation_id,
      product_id: card.product_id,
      budget_amount: card.budget_amount,
      budget_currency: card.budget_currency,
      stale_days: card.stale_days,
      stale_level: card.stale_level,
      next_activity_at: card.next_activity_at&.iso8601,
      updated_at: card.updated_at&.iso8601
    }
  end
end
