class AddScalingIndexesToCrmAiAgents < ActiveRecord::Migration[7.1]
  def change
    add_index :crm_ai_agents, [:account_id, :active], name: 'idx_crm_ai_agents_account_active'
    add_index :crm_ai_agent_inboxes, [:account_id, :inbox_id, :enabled], name: 'idx_crm_ai_agent_inboxes_lookup'
    add_index :crm_products, [:account_id, :active, :category], name: 'idx_crm_products_account_active_category'
  end
end
