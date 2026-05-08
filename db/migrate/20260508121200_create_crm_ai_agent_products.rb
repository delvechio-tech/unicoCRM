class CreateCrmAiAgentProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_ai_agent_products do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :ai_agent, null: false, foreign_key: { to_table: :crm_ai_agents }, index: true
      t.references :product, null: false, foreign_key: { to_table: :crm_products }, index: true

      t.timestamps
    end

    add_index :crm_ai_agent_products, [:ai_agent_id, :product_id], unique: true, name: 'idx_crm_ai_agent_products_unique'
  end
end
