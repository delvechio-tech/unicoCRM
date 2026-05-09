class ExtendCrmKanbanAutomation < ActiveRecord::Migration[7.1]
  def change
    add_reference :crm_kanban_cards, :last_message, foreign_key: { to_table: :messages }, index: true
    add_column :crm_kanban_cards, :next_activity_at, :datetime
    add_column :crm_kanban_cards, :auto_created, :boolean, default: false, null: false
    add_column :crm_kanban_cards, :won_at, :datetime
    add_column :crm_kanban_cards, :lost_at, :datetime
    add_column :crm_kanban_cards, :lost_reason, :string

    create_table :crm_kanban_actions do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :card, null: false, foreign_key: { to_table: :crm_kanban_cards }, index: true
      t.references :user, foreign_key: true, index: true
      t.string :action_type, null: false
      t.string :actor_type, null: false, default: 'manual'
      t.jsonb :data, default: {}, null: false

      t.timestamps
    end

    add_index :crm_kanban_actions, [:account_id, :action_type]

    create_table :crm_kanban_activities do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :card, null: false, foreign_key: { to_table: :crm_kanban_cards }, index: true
      t.references :contact, foreign_key: true, index: true
      t.references :conversation, foreign_key: true, index: true
      t.references :assignee, foreign_key: { to_table: :users }, index: true
      t.string :title, null: false
      t.text :description
      t.string :activity_type, null: false, default: 'follow_up'
      t.string :status, null: false, default: 'open'
      t.datetime :due_at
      t.datetime :completed_at
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :crm_kanban_activities, [:account_id, :status, :due_at]

    create_table :crm_kanban_webhooks do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :pipeline, foreign_key: { to_table: :crm_kanban_pipelines }, index: true
      t.string :name, null: false
      t.string :url, null: false
      t.string :access_token
      t.jsonb :events, default: [], null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
