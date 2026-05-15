class Crm::KanbanListener < BaseListener
  def message_created(event)
    message = event.data[:message]
    return unless should_process?(message)

    Crm::KanbanAutoSyncJob.perform_later(message.id)
  end

  private

  def should_process?(message)
    return false if message.blank?

    message.webhook_sendable? &&
      (message.incoming? || message.outgoing?) &&
      !message.private? &&
      message.inbox_id.present?
  end
end
