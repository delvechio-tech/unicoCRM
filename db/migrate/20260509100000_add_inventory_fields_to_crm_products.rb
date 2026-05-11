class AddInventoryFieldsToCrmProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :crm_products, :availability_status, :string, null: false, default: 'in_stock'
    add_column :crm_products, :stock_quantity, :decimal, precision: 12, scale: 2, null: false, default: 0
    add_column :crm_products, :reserved_quantity, :decimal, precision: 12, scale: 2, null: false, default: 0
    add_column :crm_products, :low_stock_threshold, :decimal, precision: 12, scale: 2, null: false, default: 0
    add_column :crm_products, :track_inventory, :boolean, null: false, default: false

    add_index :crm_products, [:account_id, :availability_status], name: 'idx_crm_products_account_availability'
    add_index :crm_products, [:account_id, :track_inventory], name: 'idx_crm_products_account_track_inventory'
  end
end
