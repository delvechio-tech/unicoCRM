class Crm::Kanban::FollowUps::IncomingIntentProcessor
  EXPLICIT_OPT_OUT_PATTERNS = [
    /n[aã]o quero mais contato/i,
    /n[aã]o me (?:mande|envie|chame|contate)/i,
    /pare de (?:me )?(?:mandar|enviar|chamar|contatar)/i,
    /remova meu contato/i,
    /n[aã]o quero mais falar/i
  ].freeze

  SOFT_NEGATIVE_PATTERNS = [
    /agora n[aã]o/i,
    /n[aã]o posso agora/i,
    /n[aã]o quero agora/i,
    /mais tarde/i,
    /outro dia/i,
    /depois falamos/i
  ].freeze

  def initialize(card:, message:)
    @card = card
    @message = message
  end

  def perform
    return unless message.incoming?

    return disqualify_card if explicit_opt_out?
    mark_reschedule_needed if soft_negative?
  end

  private

  attr_reader :card, :message

  def explicit_opt_out?
    EXPLICIT_OPT_OUT_PATTERNS.any? { |pattern| message.content.to_s.match?(pattern) }
  end

  def soft_negative?
    SOFT_NEGATIVE_PATTERNS.any? { |pattern| message.content.to_s.match?(pattern) }
  end

  def disqualify_card
    card.update!(
      status: 'lost',
      lost_reason: 'explicit_opt_out',
      metadata: card.metadata.to_h.merge(
        'follow_up_intent' => {
          'state' => 'opted_out',
          'message_id' => message.id,
          'detected_at' => Time.current.iso8601
        }
      )
    )

    Crm::Kanban::FollowUps::ScheduleCanceler.new(
      card: card,
      reason: 'explicit_opt_out',
      data: { 'message_id' => message.id }
    ).perform
  end

  def mark_reschedule_needed
    card.update!(
      metadata: card.metadata.to_h.merge(
        'follow_up_intent' => {
          'state' => 'awaiting_reschedule_preference',
          'message_id' => message.id,
          'detected_at' => Time.current.iso8601
        }
      )
    )
  end
end
