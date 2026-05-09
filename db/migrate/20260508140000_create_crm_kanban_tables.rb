class CreateCrmKanbanTables < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_kanban_pipelines do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.text :ai_rules
      t.boolean :default, null: false, default: false
      t.integer :position, null: false, default: 0
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    create_table :crm_kanban_stages do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :pipeline, null: false, foreign_key: { to_table: :crm_kanban_pipelines }, index: true
      t.string :name, null: false
      t.string :color, null: false, default: 'slate'
      t.integer :position, null: false, default: 0
      t.integer :stale_after_days, null: false, default: 3
      t.integer :win_probability, null: false, default: 0
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    create_table :crm_kanban_cards do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :pipeline, null: false, foreign_key: { to_table: :crm_kanban_pipelines }, index: true
      t.references :stage, null: false, foreign_key: { to_table: :crm_kanban_stages }, index: true
      t.references :contact, foreign_key: true, index: true
      t.references :conversation, foreign_key: true, index: true
      t.references :product, foreign_key: { to_table: :crm_products }, index: true
      t.references :assignee, foreign_key: { to_table: :users }, index: true
      t.string :title, null: false
      t.decimal :budget_amount, precision: 12, scale: 2
      t.string :budget_currency, null: false, default: 'BRL'
      t.text :summary
      t.text :notes
      t.string :status, null: false, default: 'open'
      t.string :source, null: false, default: 'manual'
      t.integer :position, null: false, default: 0
      t.datetime :stage_changed_at, null: false
      t.datetime :last_activity_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :crm_kanban_pipelines, [:account_id, :name], unique: true
    add_index :crm_kanban_pipelines, [:account_id, :default], where: '"default" = TRUE'
    add_index :crm_kanban_stages, [:account_id, :pipeline_id, :position], name: 'idx_crm_kanban_stages_order'
    add_index :crm_kanban_cards, [:account_id, :pipeline_id, :stage_id, :position], name: 'idx_crm_kanban_cards_board_order'
    add_index :crm_kanban_cards, [:account_id, :status], name: 'idx_crm_kanban_cards_status'
  end
end
