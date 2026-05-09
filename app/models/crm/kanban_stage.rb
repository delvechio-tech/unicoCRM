class Crm::KanbanStage < ApplicationRecord
  self.table_name = 'crm_kanban_stages'

  belongs_to :account
  belongs_to :pipeline, class_name: '::Crm::KanbanPipeline'

  has_many :cards, dependent: :restrict_with_error, class_name: '::Crm::KanbanCard', foreign_key: :stage_id, inverse_of: :stage

  validates :name, presence: true
  validates :position, numericality: { only_integer: true }
  validates :stale_after_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :win_probability, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validate :same_account

  private

  def same_account
    return if pipeline.blank?
    return if pipeline.account_id == account_id

    errors.add(:base, 'records must belong to the same account')
  end
end
