class CreateCrmProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_products do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :sku
      t.string :category
      t.string :currency, null: false, default: 'BRL'
      t.decimal :price, precision: 12, scale: 2
      t.boolean :active, null: false, default: true
      t.text :description
      t.text :faq
      t.text :objections
      t.text :media_notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :crm_products, [:account_id, :name]
    add_index :crm_products, [:account_id, :sku], unique: true, where: "sku IS NOT NULL AND sku <> ''"
  end
end
