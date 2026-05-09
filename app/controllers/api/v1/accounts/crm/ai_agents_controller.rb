class Api::V1::Accounts::Crm::AiAgentsController < Api::V1::Accounts::BaseController
  before_action :fetch_ai_agent, only: [:show, :update, :destroy, :playground]

  def index
    render json: Current.account.crm_ai_agents.includes(:products, :inboxes).order(updated_at: :desc).map { |agent| agent_payload(agent) }
  end

  def show
    render json: agent_payload(@ai_agent)
  end

  def create
    @ai_agent = Current.account.crm_ai_agents.new(ai_agent_params)
    @ai_agent.save!
    sync_products(@ai_agent)
    sync_inboxes(@ai_agent)
    render json: agent_payload(@ai_agent), status: :created
  end

  def update
    @ai_agent.update!(ai_agent_params)
    sync_products(@ai_agent)
    sync_inboxes(@ai_agent)
    render json: agent_payload(@ai_agent)
  end

  def destroy
    @ai_agent.destroy!
    head :ok
  end

  def playground
    render json: Crm::AiAgents::PlaygroundService.new(
      agent: @ai_agent,
      message: params[:message]
    ).perform
  end

  private

  def fetch_ai_agent
    @ai_agent = Current.account.crm_ai_agents.find(params[:id])
  end

  def ai_agent_params
    params.require(:ai_agent).permit(
      :name, :gender, :role, :communication_tone, :sales_technique,
      :n8n_webhook_url, :active, :auto_reply_enabled, :company_context,
      :objective, :personality, settings: {}
    )
  end

  def sync_products(agent)
    product_ids = Array(params.dig(:ai_agent, :product_ids)).reject(&:blank?).map(&:to_i)
    products = Current.account.crm_products.where(id: product_ids)

    agent.ai_agent_products.where.not(product_id: products.ids).destroy_all
    products.find_each do |product|
      agent.ai_agent_products.find_or_create_by!(account: Current.account, product: product)
    end
  end

  def sync_inboxes(agent)
    inbox_ids = Array(params.dig(:ai_agent, :inbox_ids)).reject(&:blank?).map(&:to_i)
    inboxes = Current.account.inboxes.where(id: inbox_ids)

    agent.ai_agent_inboxes.where.not(inbox_id: inboxes.ids).destroy_all
    inboxes.find_each do |inbox|
      agent.ai_agent_inboxes.find_or_create_by!(account: Current.account, inbox: inbox)
    end
  end

  def agent_payload(agent)
    agent.as_json(
      only: [
        :id, :name, :gender, :role, :communication_tone, :sales_technique,
        :n8n_webhook_url, :active, :auto_reply_enabled, :company_context,
        :objective, :personality, :settings, :created_at, :updated_at
      ]
    ).merge(
      product_ids: agent.products.pluck(:id),
      inbox_ids: agent.inboxes.pluck(:id)
    )
  end
end
