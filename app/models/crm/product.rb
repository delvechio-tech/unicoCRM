class Crm::Product < ApplicationRecord
  self.table_name = 'crm_products'

  belongs_to :account

  has_many :ai_agent_products, dependent: :destroy, class_name: '::Crm::AiAgentProduct', inverse_of: :product
  has_many :ai_agents, through: :ai_agent_products, source: :ai_agent

  validates :name, presence: true
  validates :sku, uniqueness: { scope: :account_id, allow_blank: true }
end
