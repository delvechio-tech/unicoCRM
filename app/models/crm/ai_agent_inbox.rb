class Crm::AiAgentInbox < ApplicationRecord
  self.table_name = 'crm_ai_agent_inboxes'

  belongs_to :account
  belongs_to :ai_agent, class_name: '::Crm::AiAgent'
  belongs_to :inbox

  validates :inbox_id, uniqueness: { scope: :ai_agent_id }
  validate :same_account

  private

  def same_account
    return if ai_agent.blank? || inbox.blank?
    return if ai_agent.account_id == account_id && inbox.account_id == account_id

    errors.add(:base, 'records must belong to the same account')
  end
end
