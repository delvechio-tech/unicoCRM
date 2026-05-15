class Crm::Kanban::AutoSyncService
  def initialize(message:)
    @message = message
    @account = message.account
    @conversation = message.conversation
    @contact = conversation&.contact
  end

  def perform
    return unless processable?

    card = nil
    action_type = nil
    sync_target = automation_target
    sync_metadata = automatic_metadata(sync_target)

    account.with_lock do
      card = existing_card
      return if card.blank? && !message.incoming?

      action_type = card.present? ? 'card.auto_synced' : 'card.created'
      card ||= create_card(sync_target)
      update_card_from_message(card, sync_target, sync_metadata)
    end

    record_auto_sync(card, action_type, sync_metadata)
    dispatch_auto_sync(card, action_type, sync_metadata)
    card
  end

  private

  attr_reader :message, :account, :conversation, :contact

  def processable?
    message.webhook_sendable? &&
      (message.incoming? || message.outgoing?) &&
      !message.private? &&
      conversation.present? &&
      contact.present?
  end

  def pipeline
    @pipeline ||= automation_target[:pipeline]
  end

  def first_stage(selected_pipeline = pipeline)
    selected_pipeline.stages.order(:position).first
  end

  def existing_card
    account.crm_kanban_cards.active.open_status.find_by(conversation: conversation) ||
      account.crm_kanban_cards.active.open_status.find_by(contact: contact)
  end

  def create_card(sync_target)
    selected_pipeline = sync_target[:pipeline]
    selected_stage = sync_target[:stage] || first_stage(selected_pipeline)

    account.crm_kanban_cards.create!(
      pipeline: selected_pipeline,
      stage: selected_stage,
      contact: contact,
      conversation: conversation,
      title: card_title,
      position: selected_stage.cards.maximum(:position).to_i + 1,
      stage_changed_at: Time.current,
      last_activity_at: Time.current,
      source: 'auto',
      auto_created: true,
      metadata: sync_metadata_for_create(sync_target)
    )
  end

  def update_card_from_message(card, sync_target, sync_metadata)
    attributes = {
      contact: contact,
      conversation: conversation,
      last_message: message,
      last_activity_at: Time.current,
      metadata: card.metadata.to_h.merge(sync_metadata)
    }

    selected_stage = sync_target[:rule].present? ? sync_target[:stage] : nil
    if selected_stage.present? && card.stage_id != selected_stage.id
      attributes[:pipeline] = selected_stage.pipeline
      attributes[:stage] = selected_stage
      attributes[:position] = selected_stage.cards.maximum(:position).to_i + 1
      attributes[:stage_changed_at] = Time.current
    end

    card.update!(attributes)
  end

  def sync_metadata_for_create(sync_target)
    automatic_metadata(sync_target)
  end

  def automatic_metadata(sync_target)
    {
      'last_auto_sync_at' => Time.current.iso8601,
      'last_message_id' => message.id,
      'last_message_content' => message.content.to_s.truncate(500),
      'last_message_type' => message.message_type,
      'inbox_id' => message.inbox_id,
      'inbox_name' => message.inbox&.name,
      'kanban_rule_id' => sync_target[:rule]&.dig('id'),
      'kanban_rule_condition' => sync_target[:rule]&.dig('condition'),
      'kanban_pipeline_id' => sync_target[:pipeline]&.id,
      'kanban_stage_id' => sync_target[:stage]&.id
    }.compact
  end

  def automation_target
    @automation_target ||= begin
      matched = automation_rules.find { |candidate| rule_matches?(candidate[:rule]) }
      selected_pipeline = matched&.dig(:pipeline) || Crm::KanbanPipeline.ensure_default_for!(account)
      selected_stage = matched.present? ? stage_for_rule(selected_pipeline, matched[:rule]) : first_stage(selected_pipeline)

      { pipeline: selected_pipeline, stage: selected_stage || first_stage(selected_pipeline), rule: matched&.dig(:rule) }
    end
  end

  def automation_rules
    account.crm_kanban_pipelines.order(:position, :id).flat_map do |record|
      Array(record.settings.to_h['automation_rules']).filter_map do |rule|
        next unless rule.is_a?(Hash) && rule['enabled'] != false

        { pipeline: record, rule: rule }
      end
    end
  end

  def rule_matches?(rule)
    return false if rule['trigger'].present? && rule['trigger'] != 'message_created'

    case rule['condition']
    when 'incoming_message'
      message.incoming?
    when 'unread'
      conversation.unread_incoming_messages.any?
    when 'waiting_reply'
      conversation.waiting_since.present?
    when 'agent_replied'
      message.outgoing?
    when 'open_conversation'
      conversation.open?
    when 'any', nil, ''
      true
    else
      false
    end
  end

  def stage_for_rule(selected_pipeline, rule)
    selected_pipeline.stages.find_by(id: rule['stage_id'])
  end

  def card_title
    contact.name.presence || contact.phone_number.presence || contact.email.presence || "Cliente ##{contact.id}"
  end

  def record_auto_sync(card, action_type, sync_metadata)
    Crm::Kanban::ActionRecorder.new(
      card: card,
      action_type: action_type,
      actor_type: 'automation',
      data: sync_metadata
    ).perform
  end

  def dispatch_auto_sync(card, action_type, sync_metadata)
    Crm::Kanban::WebhookDispatcher.new(card: card, event_name: action_type, payload: sync_metadata).perform
  end
end
