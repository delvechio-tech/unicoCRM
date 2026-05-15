class Crm::Kanban::FollowUps::ManualScheduler
  def initialize(card:, scheduled_for:, instruction: nil)
    @card = card
    @scheduled_for = scheduled_for
    @instruction = instruction
  end

  def perform
    Crm::Kanban::FollowUps::ScheduleCanceler.new(
      card: card,
      reason: 'superseded_by_manual_override'
    ).perform

    card.update!(
      metadata: card.metadata.to_h.merge(
        'follow_up_override' => {
          'mode' => 'manual'
        }
      )
    )

    schedule = card.follow_up_schedules.create!(
      account: card.account,
      pipeline: card.pipeline,
      contact: card.contact,
      conversation: card.conversation,
      source: 'manual_override',
      scheduled_for: scheduled_for,
      attempt_number: 1,
      reason: 'manual_override',
      message_instruction: instruction
    )

    schedule.events.create!(
      account: card.account,
      card: card,
      event_type: 'scheduled',
      data: {
        'scheduled_for' => schedule.scheduled_for.iso8601,
        'source' => 'manual_override'
      }
    )

    schedule
  end

  private

  attr_reader :card, :scheduled_for, :instruction
end
