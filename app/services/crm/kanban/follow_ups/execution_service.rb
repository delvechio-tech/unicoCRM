class Crm::Kanban::FollowUps::ExecutionService
  def initialize(schedule:)
    @schedule = schedule
  end

  def perform
    return unless executable?

    mark_processing
    message = create_message
    mark_sent(message)
    message
  rescue StandardError => e
    mark_failed(e)
    raise
  end

  private

  attr_reader :schedule

  delegate :card, :conversation, to: :schedule

  def executable?
    schedule.status == 'scheduled' &&
      schedule.generated_message.present? &&
      card.status == 'open' &&
      conversation.present? &&
      card.metadata.to_h.dig('follow_up_intent', 'state') != 'opted_out' &&
      !customer_replied_after_schedule?
  end

  def customer_replied_after_schedule?
    conversation.messages.incoming.where('created_at > ?', schedule.created_at).exists?
  end

  def mark_processing
    schedule.update!(status: 'processing')
    schedule.events.create!(account: schedule.account, card: card, event_type: 'processing')
  end

  def create_message
    Messages::MessageBuilder.new(
      nil,
      conversation,
      {
        content: schedule.generated_message,
        private: false,
        content_attributes: {
          source: 'crm_kanban_follow_up',
          crm_kanban_follow_up_schedule_id: schedule.id
        }
      }
    ).perform
  end

  def mark_sent(message)
    schedule.update!(status: 'sent', sent_at: Time.current)
    schedule.events.create!(
      account: schedule.account,
      card: card,
      event_type: 'sent',
      data: { 'message_id' => message.id }
    )
    Crm::Kanban::FollowUps::CadenceAdvancer.new(schedule: schedule).perform
  end

  def mark_failed(error)
    return if schedule.blank? || %w[sent canceled].include?(schedule.status)

    schedule.update!(status: 'failed')
    schedule.events.create!(
      account: schedule.account,
      card: card,
      event_type: 'failed',
      data: { 'error_class' => error.class.name, 'error_message' => error.message }
    )
  end
end
