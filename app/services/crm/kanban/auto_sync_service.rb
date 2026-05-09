class Crm::Kanban::AutoSyncService
  def initialize(message:)
    @message = message
    @account = message.account
    @conversation = message.conversation
    @contact = conversation&.contact
  end

  def perform
    return unless processable?

    card = existing_card
    action_type = card.present? ? 'card.auto_synced' : 'card.created'
    card ||= create_card
    update_card_from_message(card)
    record_auto_sync(card, action_type)
    dispatch_auto_sync(card, action_type)
    card
  end

  private

  attr_reader :message, :account, :conversation, :contact

  def processable?
    message.webhook_sendable? &&
      message.incoming? &&
      !message.private? &&
      conversation.present? &&
      contact.present?
  end

  def pipeline
    @pipeline ||= Crm::KanbanPipeline.ensure_default_for!(account)
  end

  def first_stage
    @first_stage ||= pipeline.stages.order(:position).first
  end

  def existing_card
    pipeline.cards.active.open_status.find_by(conversation: conversation) ||
      pipeline.cards.active.open_status.find_by(contact: contact)
  end

  def create_card
    account.crm_kanban_cards.create!(
      pipeline: pipeline,
      stage: first_stage,
      contact: contact,
      conversation: conversation,
      title: card_title,
      position: first_stage.cards.maximum(:position).to_i + 1,
      stage_changed_at: Time.current,
      last_activity_at: Time.current,
      source: 'auto',
      auto_created: true,
      metadata: automatic_metadata
    )
  end

  def update_card_from_message(card)
    card.update!(
      contact: contact,
      conversation: conversation,
      last_message: message,
      last_activity_at: Time.current,
      metadata: card.metadata.merge(automatic_metadata)
    )
  end

  def automatic_metadata
    {
      'last_auto_sync_at' => Time.current.iso8601,
      'last_message_id' => message.id,
      'last_message_content' => message.content.to_s.truncate(500),
      'last_message_type' => message.message_type,
      'inbox_id' => message.inbox_id,
      'inbox_name' => message.inbox&.name
    }.compact
  end

  def card_title
    contact.name.presence || contact.phone_number.presence || contact.email.presence || "Cliente ##{contact.id}"
  end

  def record_auto_sync(card, action_type)
    Crm::Kanban::ActionRecorder.new(
      card: card,
      action_type: action_type,
      actor_type: 'automation',
      data: automatic_metadata
    ).perform
  end

  def dispatch_auto_sync(card, action_type)
    Crm::Kanban::WebhookDispatcher.new(card: card, event_name: action_type, payload: automatic_metadata).perform
  end
end
