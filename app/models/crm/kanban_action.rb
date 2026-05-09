class Crm::KanbanAction < ApplicationRecord
  self.table_name = 'crm_kanban_actions'

  ACTION_TYPES = %w[
    card.created
    card.updated
    card.moved
    card.archived
    card.auto_synced
    activity.created
    activity.updated
    activity.completed
  ].freeze

  belongs_to :account
  belongs_to :card, class_name: '::Crm::KanbanCard'
  belongs_to :user, optional: true

  validates :action_type, inclusion: { in: ACTION_TYPES }
  validates :actor_type, presence: true
  validate :same_account

  private

  def same_account
    return if account_id.blank?

    errors.add(:card, 'must belong to the same account') if card.present? && card.account_id != account_id
    errors.add(:user, 'must belong to the same account') if user.present? && !account.users.exists?(user.id)
  end
end
