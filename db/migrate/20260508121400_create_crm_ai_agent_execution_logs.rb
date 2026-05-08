class CreateCrmAiAgentExecutionLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_ai_agent_execution_logs do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :ai_agent, null: false, foreign_key: { to_table: :crm_ai_agents }, index: true
      t.references :conversation, foreign_key: true, index: true
      t.references :message, foreign_key: true, index: true
      t.string :status, null: false, default: 'pending'
      t.string :executor, null: false, default: 'n8n'
      t.string :error_message
      t.jsonb :request_payload, null: false, default: {}
      t.jsonb :response_payload, null: false, default: {}

      t.timestamps
    end
  end
end
