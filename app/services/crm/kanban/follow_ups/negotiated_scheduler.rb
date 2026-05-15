class Crm::Kanban::FollowUps::NegotiatedScheduler
  SOURCES = %w[customer_requested ai_negotiated].freeze

  def initialize(card:, scheduled_for:, source:, instruction: nil, metadata: {})
    @card = card
    @scheduled_for = scheduled_for
    @source = source
    @instruction = instruction
    @metadata = metadata
    @settings = card.pipeline.settings.to_h['follow_up_settings'].to_h
  end

  def perform
    return unless schedulable?

    cancel_existing_schedules
    schedule = create_schedule
    mark_intent_as_scheduled(schedule)
    record_event(schedule)
    schedule
  end

  private

  attr_reader :card, :scheduled_for, :source, :instruction, :metadata, :settings

  def schedulable?
    SOURCES.include?(source) && card.status == 'open'
  end

  def adjusted_time
    Crm::Kanban::FollowUps::ScheduleTimeAdjuster.new(
      settings: settings,
      candidate: scheduled_for
    ).perform
  end

  def cancel_existing_schedules
    Crm::Kanban::FollowUps::ScheduleCanceler.new(
      card: card,
      reason: 'superseded_by_negotiated_return'
    ).perform
  end

  def create_schedule
    card.follow_up_schedules.create!(
      account: card.account,
      pipeline: card.pipeline,
      contact: card.contact,
      conversation: card.conversation,
      source: source,
      scheduled_for: adjusted_time,
      attempt_number: 1,
      reason: 'negotiated_return',
      message_instruction: instruction,
      metadata: metadata
    )
  end

  def mark_intent_as_scheduled(schedule)
    card.update!(
      metadata: card.metadata.to_h.merge(
        'follow_up_intent' => {
          'state' => 'scheduled_return',
          'scheduled_for' => schedule.scheduled_for.iso8601,
          'source' => source
        }
      )
    )
  end

  def record_event(schedule)
    schedule.events.create!(
      account: card.account,
      card: card,
      event_type: 'scheduled',
      data: {
        'scheduled_for' => schedule.scheduled_for.iso8601,
        'source' => source
      }
    )
  end
end
