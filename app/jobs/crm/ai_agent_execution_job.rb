class Crm::AiAgentExecutionJob < ApplicationJob
  queue_as :medium

  def perform(message_id)
    message = Message
              .includes(:account, :inbox, :conversation, :sender, attachments: { file_attachment: :blob })
              .find_by(id: message_id)
    return if message.blank?

    Crm::AiAgents::N8nExecutor.new(message: message).perform
  end
end
