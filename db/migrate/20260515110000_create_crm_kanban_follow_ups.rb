class CreateCrmKanbanFollowUps < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_kanban_follow_up_schedules do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.references :pipeline, null: false, foreign_key: { to_table: :crm_kanban_pipelines }, index: false
      t.references :card, null: false, foreign_key: { to_table: :crm_kanban_cards }, index: false
      t.references :contact, foreign_key: true, index: false
      t.references :conversation, foreign_key: true, index: false
      t.string :source, null: false
      t.string :status, null: false, default: 'scheduled'
      t.datetime :scheduled_for, null: false
      t.integer :attempt_number, null: false, default: 1
      t.integer :cadence_step
      t.string :channel_type
      t.string :reason
      t.text :message_instruction
      t.text :generated_message
      t.jsonb :metadata, null: false, default: {}
      t.datetime :canceled_at
      t.datetime :sent_at
      t.timestamps
    end

    add_index :crm_kanban_follow_up_schedules, [:account_id, :status, :scheduled_for], name: 'idx_crm_follow_up_due'
    add_index :crm_kanban_follow_up_schedules, [:card_id, :status], name: 'idx_crm_follow_up_card_status'

    create_table :crm_kanban_follow_up_events do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.references :schedule, null: false, foreign_key: { to_table: :crm_kanban_follow_up_schedules }, index: false
      t.references :card, null: false, foreign_key: { to_table: :crm_kanban_cards }, index: false
      t.string :event_type, null: false
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end

    add_index :crm_kanban_follow_up_events, [:schedule_id, :created_at], name: 'idx_crm_follow_up_events_schedule_time'
    add_index :crm_kanban_follow_up_events, [:card_id, :created_at], name: 'idx_crm_follow_up_events_card_time'
  end
end
