class Crm::AiAgents::PayloadBuilder
  SCHEMA_VERSION = 'v1'.freeze
  RECENT_MESSAGES_LIMIT = 8

  def initialize(agent:, message:)
    @agent = agent
    @message = message
    @account = message.account
    @conversation = message.conversation
  end

  def perform
    {
      event: 'crm_ai_agent.message_created',
      schema_version: SCHEMA_VERSION,
      session_id: session_id,
      message_id: message.id,
      execution: execution_payload,
      account: account_payload,
      agent: agent_payload,
      inbox: inbox_payload,
      conversation: conversation_payload,
      contact: contact_payload,
      message: message_payload(message),
      recent_messages: recent_messages_payload,
      tool_urls: tool_urls_payload,
      instructions: instructions_payload
    }
  end

  private

  attr_reader :agent, :message, :account, :conversation

  def execution_payload
    {
      mode: agent.auto_reply_enabled? ? 'auto_reply' : 'suggestion',
      source: 'unicocrm',
      generated_at: Time.current.iso8601
    }
  end

  def account_payload
    {
      id: account.id,
      name: account.name
    }
  end

  def agent_payload
    {
      id: agent.id,
      name: agent.name,
      role: agent.role,
      gender: agent.gender,
      communication_tone: agent.communication_tone,
      sales_technique: agent.sales_technique,
      company_context: agent.company_context,
      objective: agent.objective,
      personality: agent.personality,
      auto_reply_enabled: agent.auto_reply_enabled,
      settings: agent.settings
    }
  end

  def inbox_payload
    inbox = message.inbox
    {
      id: inbox.id,
      name: inbox.name,
      channel_type: inbox.channel_type
    }
  end

  def conversation_payload
    {
      id: conversation.id,
      display_id: conversation.display_id,
      session_id: session_id,
      status: conversation.status,
      priority: conversation.priority,
      labels: conversation.label_list,
      custom_attributes: conversation.custom_attributes,
      additional_attributes: conversation.additional_attributes,
      created_at: conversation.created_at&.iso8601,
      last_activity_at: conversation.last_activity_at&.iso8601
    }
  end

  def contact_payload
    contact = conversation.contact
    return {} if contact.blank?

    {
      id: contact.id,
      name: contact.name,
      phone_number: contact.phone_number,
      email: contact.email,
      identifier: contact.identifier,
      custom_attributes: contact.custom_attributes,
      additional_attributes: contact.additional_attributes
    }
  end

  def message_payload(record)
    {
      id: record.id,
      source_id: record.source_id,
      message_type: record.message_type,
      content_type: record.content_type,
      content: record.content_for_llm,
      private: record.private,
      created_at: record.created_at&.iso8601,
      attachments: record.attachments.map { |attachment| attachment_payload(attachment) }
    }
  end

  def attachment_payload(attachment)
    {
      id: attachment.id,
      file_type: attachment.file_type,
      content_type: attachment.file.attached? ? attachment.file.content_type : nil,
      file_size: attachment.file.attached? ? attachment.file.byte_size : nil,
      data_url: attachment.download_url.presence || attachment.external_url,
      fallback_title: attachment.fallback_title,
      transcribed_text: attachment.meta&.dig('transcribed_text')
    }.compact
  end

  def recent_messages_payload
    conversation.messages
                .chat
                .where(account_id: account.id)
                .includes(attachments: { file_attachment: :blob })
                .last(RECENT_MESSAGES_LIMIT)
                .map { |record| message_payload(record) }
  end

  def tool_urls_payload
    {
      search_products: tool_url('search_products'),
      get_product: tool_url('products/{product_id}'),
      search_faqs: tool_url('search_faqs'),
      search_kanban_cards: tool_url('search_kanban_cards'),
      update_kanban_card: tool_url('kanban_cards/{card_id}'),
      create_kanban_activity: tool_url('kanban_cards/{card_id}/activities')
    }
  end

  def tool_url(action)
    path = "/api/v1/accounts/#{account.id}/crm/ai_agents/#{agent.id}/tools/#{action}"
    return path if frontend_url.blank?

    "#{frontend_url}#{path}"
  end

  def frontend_url
    @frontend_url ||= ENV.fetch('FRONTEND_URL', nil).to_s.delete_suffix('/')
  end

  def instructions_payload
    {
      knowledge_policy: [
        'Use tool_urls to fetch product and FAQ data on demand.',
        'Do not assume product prices, availability, quantities, reservations, or policies that were not returned by the tools.'
      ].join(' '),
      product_policy: [
        'Search products before recommending a specific product.',
        'Check availability_status, sale_available, and available_quantity before saying an item can be sold.',
        'Ask a clarification question when the search result is empty or ambiguous.'
      ].join(' '),
      kanban_policy: [
        'Use kanban tools when the customer shows buying intent, asks for a proposal, schedules a follow-up, wins, or refuses.',
        'Create activities for promised calls, meetings, deadlines, proposals, and follow-ups.'
      ].join(' ')
    }
  end

  def session_id
    @session_id ||= "account:#{account.id}:conversation:#{conversation.id}"
  end
end
