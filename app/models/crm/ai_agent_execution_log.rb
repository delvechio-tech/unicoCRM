class Crm::AiAgentExecutionLog < ApplicationRecord
  self.table_name = 'crm_ai_agent_execution_logs'

  belongs_to :account
  belongs_to :ai_agent, class_name: '::Crm::AiAgent'
  belongs_to :conversation, optional: true
  belongs_to :message, optional: true

  validates :status, presence: true
  validates :executor, presence: true
end
