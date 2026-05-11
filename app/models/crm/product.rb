class Crm::Product < ApplicationRecord
  self.table_name = 'crm_products'

  AVAILABILITY_STATUSES = %w[in_stock out_of_stock pre_order discontinued].freeze

  belongs_to :account
  has_many_attached :media_files

  has_many :ai_agent_products, dependent: :destroy, class_name: '::Crm::AiAgentProduct', inverse_of: :product
  has_many :ai_agents, through: :ai_agent_products, source: :ai_agent

  validates :name, presence: true
  validates :sku, uniqueness: { scope: :account_id, allow_blank: true }
  validates :availability_status, inclusion: { in: AVAILABILITY_STATUSES }
  validates :stock_quantity, :reserved_quantity, :low_stock_threshold,
            numericality: { greater_than_or_equal_to: 0 }
  validate :reserved_quantity_cannot_exceed_stock, if: :track_inventory?

  def available_quantity
    return nil unless track_inventory?

    [stock_quantity.to_d - reserved_quantity.to_d, 0.to_d].max
  end

  def low_stock?
    return false unless track_inventory?
    return false if discontinued?

    available_quantity <= low_stock_threshold.to_d
  end

  def sale_available?
    return false if discontinued?
    return true if pre_order?
    return availability_status == 'in_stock' unless track_inventory?

    available_quantity.positive? && availability_status == 'in_stock'
  end

  AVAILABILITY_STATUSES.each do |status|
    define_method("#{status}?") do
      availability_status == status
    end
  end

  private

  def reserved_quantity_cannot_exceed_stock
    return if reserved_quantity.to_d <= stock_quantity.to_d

    errors.add(:reserved_quantity, 'cannot exceed stock quantity')
  end
end
