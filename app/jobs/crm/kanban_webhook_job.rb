class Crm::KanbanWebhookJob < ApplicationJob
  queue_as :medium

  def perform(webhook_id, event_name, payload)
    webhook = Crm::KanbanWebhook.find_by(id: webhook_id)
    return if webhook.blank? || !webhook.active?

    Webhooks::Trigger.execute(
      webhook.url,
      payload.with_indifferent_access.merge(event: event_name),
      :crm_kanban_webhook,
      secret: webhook.access_token
    )
  end
end
