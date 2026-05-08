class CreateCrmAiAgentInboxes < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_ai_agent_inboxes do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :ai_agent, null: false, foreign_key: { to_table: :crm_ai_agents }, index: true
      t.references :inbox, null: false, foreign_key: true, index: true
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :crm_ai_agent_inboxes, [:ai_agent_id, :inbox_id], unique: true, name: 'idx_crm_ai_agent_inboxes_unique'
  end
end
