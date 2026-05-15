class Crm::Kanban::FollowUps::GenerationService
  def initialize(schedule:)
    @schedule = schedule
  end

  def perform
    return schedule.generated_message if schedule.generated_message.present?
    return unless generatable?

    result = Captain::KanbanFollowUpMessageService.new(
      account: schedule.account,
      conversation_display_id: schedule.conversation.display_id,
      instruction: generation_instruction,
      schedule_context: schedule_context
    ).perform

    return record_failure(result[:error]) if result[:error]

    schedule.update!(
      generated_message: result[:message],
      metadata: schedule.metadata.to_h.merge(
        'review_state' => review_required? ? 'pending_review' : 'approved'
      )
    )
    schedule.events.create!(
      account: schedule.account,
      card: schedule.card,
      event_type: 'generated'
    )
    schedule.generated_message
  end

  private

  attr_reader :schedule

  def generatable?
    schedule.status == 'scheduled' &&
      schedule.conversation.present? &&
      schedule.card.status == 'open' &&
      schedule.card.metadata.to_h.dig('follow_up_intent', 'state') != 'opted_out'
  end

  def generation_instruction
    schedule.message_instruction.presence ||
      schedule.pipeline.settings.to_h.dig('follow_up_settings', 'instruction').presence ||
      'Retome a conversa de forma breve, util e contextual.'
  end

  def schedule_context
    {
      source: schedule.source,
      reason: schedule.reason,
      attempt_number: schedule.attempt_number,
      scheduled_for: schedule.scheduled_for.iso8601,
      follow_up_intent: schedule.card.metadata.to_h['follow_up_intent']
    }.compact
  end

  def review_required?
    schedule.pipeline.settings.to_h.dig('follow_up_settings', 'delivery_mode') == 'review_before_send'
  end

  def record_failure(error)
    schedule.events.create!(
      account: schedule.account,
      card: schedule.card,
      event_type: 'generation_failed',
      data: { 'error' => error }
    )
    nil
  end
end
