class Crm::AiAgentProduct < ApplicationRecord
  self.table_name = 'crm_ai_agent_products'

  belongs_to :account
  belongs_to :ai_agent, class_name: '::Crm::AiAgent'
  belongs_to :product, class_name: '::Crm::Product'

  validates :product_id, uniqueness: { scope: :ai_agent_id }
  validate :same_account

  private

  def same_account
    return if ai_agent.blank? || product.blank?
    return if ai_agent.account_id == account_id && product.account_id == account_id

    errors.add(:base, 'records must belong to the same account')
  end
end
