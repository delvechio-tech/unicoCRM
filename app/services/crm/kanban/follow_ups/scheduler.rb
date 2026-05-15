class Crm::Kanban::FollowUps::Scheduler
  def initialize(card:, message:)
    @card = card
    @message = message
    @settings = card.pipeline.settings.to_h['follow_up_settings'].to_h
  end

  def perform
    return unless schedulable?

    cancel_existing_schedules
    schedule = create_schedule
    record_event(schedule)
    schedule
  end

  private

  attr_reader :card, :message, :settings

  def schedulable?
    message.outgoing? &&
      settings['enabled'] == true &&
      card.status == 'open' &&
      !follow_up_overridden? &&
      first_step.present?
  end

  def first_step
    @first_step ||= channel_override || Array(settings['cadence']).first
  end

  def follow_up_overridden?
    %w[paused manual].include?(card.metadata.to_h.dig('follow_up_override', 'mode'))
  end

  def delay_value
    first_step['delay_value'].to_i
  end

  def delay_unit
    first_step['delay_unit'].presence || 'day'
  end

  def scheduled_for
    Crm::Kanban::FollowUps::ScheduleTimeAdjuster.new(
      settings: settings,
      candidate: delay_value.public_send(delay_unit.pluralize).from_now
    ).perform
  end

  def channel_override
    Array(settings['channel_overrides']).find do |rule|
      rule['channel'] == normalized_channel_type
    end
  end

  def normalized_channel_type
    message.inbox&.channel_type.to_s.demodulize.underscore
  end

  def cancel_existing_schedules
    Crm::Kanban::FollowUps::ScheduleCanceler.new(
      card: card,
      reason: 'superseded_by_new_outgoing_message',
      data: { 'message_id' => message.id }
    ).perform
  end

  def create_schedule
    card.follow_up_schedules.create!(
      account: card.account,
      pipeline: card.pipeline,
      contact: card.contact,
      conversation: card.conversation,
      source: 'cadence',
      scheduled_for: scheduled_for,
      attempt_number: 1,
      cadence_step: 1,
      channel_type: message.inbox&.channel_type,
      reason: 'last_outgoing_message_without_customer_reply',
      message_instruction: settings['instruction'],
      metadata: {
        'message_id' => message.id,
        'trigger' => settings['trigger'],
        'cadence_step_id' => first_step['id']
      }.compact
    )
  end

  def record_event(schedule)
    schedule.events.create!(
      account: card.account,
      card: card,
      event_type: 'scheduled',
      data: {
        'message_id' => message.id,
        'scheduled_for' => schedule.scheduled_for.iso8601
      }
    )
  end
end
