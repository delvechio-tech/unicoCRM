class CreateCrmAiAgents < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_ai_agents do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :gender
      t.string :role
      t.string :communication_tone
      t.string :sales_technique
      t.string :n8n_webhook_url
      t.boolean :active, null: false, default: true
      t.boolean :auto_reply_enabled, null: false, default: false
      t.text :company_context
      t.text :objective
      t.text :personality
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :crm_ai_agents, [:account_id, :name], unique: true
  end
end
