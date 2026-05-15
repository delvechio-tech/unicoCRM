class Crm::KanbanAutoSyncJob < ApplicationJob
  queue_as :medium

  def perform(message_id)
    message = Message
              .includes(:account, :inbox, conversation: :contact)
              .find_by(id: message_id)
    return if message.blank?

    card = Crm::Kanban::AutoSyncService.new(message: message).perform
    return if card.blank?

    Crm::Kanban::FollowUps::CancellationService.new(card: card, message: message).perform
    Crm::Kanban::FollowUps::IncomingIntentProcessor.new(card: card, message: message).perform
    Crm::Kanban::FollowUps::Scheduler.new(card: card, message: message).perform
  end
end
