class Crm::Kanban::FollowUps::CancellationService
  def initialize(card:, message:)
    @card = card
    @message = message
  end

  def perform
    return unless message.incoming?

    Crm::Kanban::FollowUps::ScheduleCanceler.new(
      card: card,
      reason: 'customer_replied',
      data: { 'message_id' => message.id }
    ).perform
  end

  private

  attr_reader :card, :message
end
