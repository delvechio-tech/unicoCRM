class Crm::AiAgentListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    return unless should_process?(message)

    Crm::AiAgentExecutionJob.perform_later(message.id)
  end

  private

  def should_process?(message)
    message.webhook_sendable? &&
      message.incoming? &&
      !message.private? &&
      message.inbox_id.present?
  end
end
