class Crm::KanbanActivity < ApplicationRecord
  self.table_name = 'crm_kanban_activities'

  ACTIVITY_TYPES = %w[follow_up call meeting proposal task].freeze
  STATUSES = %w[open completed canceled].freeze

  belongs_to :account
  belongs_to :card, class_name: '::Crm::KanbanCard'
  belongs_to :contact, optional: true
  belongs_to :conversation, optional: true
  belongs_to :assignee, optional: true, class_name: 'User'

  validates :title, presence: true
  validates :activity_type, inclusion: { in: ACTIVITY_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validate :same_account

  before_validation :apply_defaults
  before_validation :sync_from_card
  after_commit :refresh_card_next_activity

  scope :open_status, -> { where(status: 'open') }
  scope :ordered, -> { order(Arel.sql('due_at ASC NULLS LAST'), :created_at) }

  def complete!
    update!(status: 'completed', completed_at: Time.current)
  end

  private

  def apply_defaults
    self.status = status.presence || 'open'
    self.activity_type = activity_type.presence || 'follow_up'
  end

  def sync_from_card
    return if card.blank?

    self.account = card.account
    self.contact ||= card.contact
    self.conversation ||= card.conversation
    self.assignee ||= card.assignee
  end

  def refresh_card_next_activity
    next_activity_at = card.activities.open_status.minimum(:due_at)
    card.update_column(:next_activity_at, next_activity_at)
  end

  def same_account
    return if account_id.blank?

    errors.add(:card, 'must belong to the same account') if card.present? && card.account_id != account_id
    errors.add(:contact, 'must belong to the same account') if contact.present? && contact.account_id != account_id
    errors.add(:conversation, 'must belong to the same account') if conversation.present? && conversation.account_id != account_id
    errors.add(:assignee, 'must belong to the same account') if assignee.present? && !account.users.exists?(assignee.id)
  end
end
