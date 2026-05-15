class Crm::KanbanFollowUpEvent < ApplicationRecord
  self.table_name = 'crm_kanban_follow_up_events'

  belongs_to :account
  belongs_to :schedule, class_name: '::Crm::KanbanFollowUpSchedule'
  belongs_to :card, class_name: '::Crm::KanbanCard'

  validates :event_type, presence: true
  validate :same_account

  private

  def same_account
    return if account_id.blank?

    errors.add(:schedule, 'must belong to the same account') if schedule.present? && schedule.account_id != account_id
    errors.add(:card, 'must belong to the same account') if card.present? && card.account_id != account_id
  end
end
