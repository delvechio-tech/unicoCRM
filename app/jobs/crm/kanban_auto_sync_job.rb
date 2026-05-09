class Crm::KanbanAutoSyncJob < ApplicationJob
  queue_as :medium

  def perform(message_id)
    message = Message
              .includes(:account, :inbox, conversation: :contact)
              .find_by(id: message_id)
    return if message.blank?

    Crm::Kanban::AutoSyncService.new(message: message).perform
  end
end
