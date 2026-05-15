class Crm::Kanban::FollowUps::CadenceAdvancer
  def initialize(schedule:)
    @schedule = schedule
    @settings = schedule.pipeline.settings.to_h['follow_up_settings'].to_h
  end

  def perform
    return unless advanceable?

    return schedule_next_step if next_step.present? && below_attempt_limit?
    return schedule_long_term_return if long_term_enabled?

    record_exhausted
    nil
  end

  private

  attr_reader :schedule, :settings

  delegate :card, to: :schedule

  def advanceable?
    schedule.source == 'cadence' &&
      schedule.status == 'sent' &&
      card.status == 'open'
  end

  def cadence_steps
    Array(settings['cadence'])
  end

  def next_step
    cadence_steps[schedule.cadence_step.to_i]
  end

  def max_attempts
    settings['max_attempts'].presence&.to_i || cadence_steps.length
  end

  def below_attempt_limit?
    schedule.attempt_number.to_i < max_attempts
  end

  def long_term_enabled?
    settings['long_term_enabled'] == true
  end

  def schedule_next_step
    next_schedule = card.follow_up_schedules.create!(
      account: card.account,
      pipeline: card.pipeline,
      contact: card.contact,
      conversation: card.conversation,
      source: 'cadence',
      scheduled_for: scheduled_for(next_step),
      attempt_number: schedule.attempt_number + 1,
      cadence_step: schedule.cadence_step + 1,
      channel_type: schedule.channel_type,
      reason: 'cadence_continued_without_customer_reply',
      message_instruction: settings['instruction'],
      metadata: {
        'previous_schedule_id' => schedule.id,
        'cadence_step_id' => next_step['id']
      }.compact
    )

    next_schedule.events.create!(
      account: card.account,
      card: card,
      event_type: 'scheduled',
      data: {
        'previous_schedule_id' => schedule.id,
        'scheduled_for' => next_schedule.scheduled_for.iso8601
      }
    )
    next_schedule
  end

  def scheduled_for(step)
    candidate = step['delay_value'].to_i.public_send((step['delay_unit'].presence || 'day').pluralize).from_now
    Crm::Kanban::FollowUps::ScheduleTimeAdjuster.new(settings: settings, candidate: candidate).perform
  end

  def schedule_long_term_return
    Crm::Kanban::FollowUps::LongTermScheduler.new(card: card).perform
  end

  def record_exhausted
    schedule.events.create!(
      account: card.account,
      card: card,
      event_type: 'cadence_exhausted',
      data: { 'attempt_number' => schedule.attempt_number }
    )
  end
end
