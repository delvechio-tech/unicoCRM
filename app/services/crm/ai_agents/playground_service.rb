class Crm::AiAgents::PlaygroundService
  DEFAULT_MODEL = 'gpt-5.2'.freeze
  DEFAULT_TIMEOUT = 30

  def initialize(agent:, message:)
    @agent = agent
    @message = message.to_s.strip
  end

  def perform
    products = Crm::AiAgents::ProductSearch.new(agent: agent, query: message, limit: 5).product_payloads
    return fallback_response(products) if openai_api_key.blank?

    {
      mode: 'openai',
      message: openai_response(products),
      products: products
    }
  rescue StandardError => e
    Rails.logger.warn("[CRM AI Agents] Playground fallback for agent #{agent.id}: #{e.message}")
    fallback_response(products)
  end

  private

  attr_reader :agent, :message

  def openai_response(products)
    response = RestClient::Request.execute(
      method: :post,
      url: 'https://api.openai.com/v1/responses',
      payload: openai_payload(products).to_json,
      headers: {
        authorization: "Bearer #{openai_api_key}",
        content_type: :json,
        accept: :json
      },
      timeout: DEFAULT_TIMEOUT
    )

    parsed_response_text(JSON.parse(response.body))
  end

  def openai_payload(products)
    {
      model: ENV.fetch('OPENAI_MODEL', DEFAULT_MODEL),
      instructions: instructions,
      input: user_input(products),
      store: false
    }
  end

  def instructions
    <<~TEXT.squish
      Voce e um agente de atendimento e vendas do UnicoCRM.
      Responda em portugues do Brasil, com clareza e sem inventar informacoes.
      Use apenas os produtos e dados fornecidos no contexto.
      Se nao houver produto relevante, peca mais detalhes ao cliente.
    TEXT
  end

  def user_input(products)
    <<~TEXT
      Mensagem do cliente: #{message}

      Agente:
      Nome: #{agent.name}
      Papel: #{agent.role}
      Tom: #{agent.communication_tone}
      Objetivo: #{agent.objective}
      Personalidade: #{agent.personality}

      Produtos encontrados:
      #{products.to_json}
    TEXT
  end

  def parsed_response_text(body)
    return body['output_text'] if body['output_text'].present?

    Array(body['output']).filter_map do |output|
      Array(output['content']).filter_map { |content| content['text'] }.join("\n")
    end.join("\n").presence || 'Nao consegui gerar uma resposta agora.'
  end

  def fallback_response(products)
    product = products.first
    return no_product_response if product.blank?

    {
      mode: 'fallback',
      message: "Encontrei #{product[:name]}. #{product[:description].presence || 'Posso te explicar os detalhes e tirar suas duvidas.'}",
      products: products
    }
  end

  def no_product_response
    {
      mode: 'fallback',
      message: 'Nao encontrei um produto claro para essa pergunta. Pode me dar mais detalhes do que voce procura?',
      products: []
    }
  end

  def openai_api_key
    ENV.fetch('OPENAI_API_KEY', nil)
  end
end
