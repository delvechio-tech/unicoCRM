class Crm::AiAgents::N8nExecutor
  DEFAULT_TIMEOUT = 15

  def initialize(message:)
    @message = message
    @account = message.account
  end

  def perform
    agents.find_each do |agent|
      deliver_to_agent(agent)
    end
  end

  private

  attr_reader :message, :account

  def agents
    account.crm_ai_agents
           .joins(:ai_agent_inboxes)
           .where(active: true, ai_agent_inboxes: { inbox_id: message.inbox_id, enabled: true })
           .where.not(n8n_webhook_url: [nil, ''])
           .distinct
  end

  def deliver_to_agent(agent)
    payload = payload_for(agent)
    log = create_log(agent, payload)
    response = post(agent.n8n_webhook_url, payload)

    log.update!(
      status: response.code.to_i.between?(200, 299) ? 'success' : 'failed',
      response_payload: response_payload(response),
      error_message: response.code.to_i.between?(200, 299) ? nil : "HTTP #{response.code}"
    )
  rescue RestClient::ExceptionWithResponse => e
    log&.update!(
      status: 'failed',
      response_payload: e.response ? response_payload(e.response) : {},
      error_message: "HTTP #{e.http_code}: #{e.message}"
    )
    Rails.logger.warn(
      "[CRM AI Agents] n8n rejected message #{message.id} for agent #{agent.id}: #{e.message}"
    )
  rescue StandardError => e
    log&.update!(status: 'failed', error_message: e.message)
    Rails.logger.warn(
      "[CRM AI Agents] Failed to deliver message #{message.id} to agent #{agent.id}: #{e.message}"
    )
  end

  def create_log(agent, payload)
    agent.execution_logs.create!(
      account: account,
      conversation: message.conversation,
      message: message,
      status: 'pending',
      executor: 'n8n',
      request_payload: payload
    )
  end

  def post(url, payload)
    RestClient::Request.execute(
      method: :post,
      url: url,
      payload: payload.to_json,
      headers: { content_type: :json, accept: :json },
      timeout: DEFAULT_TIMEOUT
    )
  end

  def response_payload(response)
    {
      code: response.code,
      body: parsed_response_body(response.body)
    }
  end

  def parsed_response_body(body)
    return {} if body.blank?

    JSON.parse(body)
  rescue JSON::ParserError
    { raw: body.to_s.truncate(10_000) }
  end

  def payload_for(agent)
    Crm::AiAgents::PayloadBuilder.new(agent: agent, message: message).perform
  end
end
