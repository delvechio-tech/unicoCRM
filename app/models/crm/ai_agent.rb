class Crm::AiAgent < ApplicationRecord
  self.table_name = 'crm_ai_agents'

  belongs_to :account

  has_many :ai_agent_products, dependent: :destroy, class_name: '::Crm::AiAgentProduct', inverse_of: :ai_agent
  has_many :products, through: :ai_agent_products, source: :product
  has_many :ai_agent_inboxes, dependent: :destroy, class_name: '::Crm::AiAgentInbox', inverse_of: :ai_agent
  has_many :inboxes, through: :ai_agent_inboxes, source: :inbox
  has_many :execution_logs, dependent: :destroy_async, class_name: '::Crm::AiAgentExecutionLog', inverse_of: :ai_agent

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :n8n_webhook_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
end
