class Crm::Kanban::FollowUps::LongTermScheduler
  def initialize(card:)
    @card = card
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

  attr_reader :card, :settings

  def schedulable?
    settings['long_term_enabled'] == true &&
      card.status == 'open' &&
      !follow_up_overridden? &&
      delay_value.positive?
  end

  def follow_up_overridden?
    %w[paused manual].include?(card.metadata.to_h.dig('follow_up_override', 'mode'))
  end

  def delay_value
    settings['long_term_delay_value'].to_i
  end

  def delay_unit
    settings['long_term_delay_unit'].presence || 'month'
  end

  def scheduled_for
    candidate = delay_value.public_send(delay_unit.pluralize).from_now
    Crm::Kanban::FollowUps::ScheduleTimeAdjuster.new(
      settings: settings,
      candidate: candidate
    ).perform
  end

  def cancel_existing_schedules
    Crm::Kanban::FollowUps::ScheduleCanceler.new(
      card: card,
      reason: 'superseded_by_long_term_return'
    ).perform
  end

  def create_schedule
    card.follow_up_schedules.create!(
      account: card.account,
      pipeline: card.pipeline,
      contact: card.contact,
      conversation: card.conversation,
      source: 'long_term_reactivation',
      scheduled_for: scheduled_for,
      attempt_number: 1,
      reason: 'long_term_return',
      message_instruction: settings['instruction'],
      metadata: {
        'trigger' => 'long_term_return'
      }
    )
  end

  def mark_intent_as_scheduled(schedule)
    card.update!(
      metadata: card.metadata.to_h.merge(
        'follow_up_intent' => {
          'state' => 'long_term_scheduled',
          'scheduled_for' => schedule.scheduled_for.iso8601
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
        'source' => 'long_term_reactivation'
      }
    )
  end
end
