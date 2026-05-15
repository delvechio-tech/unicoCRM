class Crm::KanbanCard < ApplicationRecord
  self.table_name = 'crm_kanban_cards'

  belongs_to :account
  belongs_to :pipeline, class_name: '::Crm::KanbanPipeline'
  belongs_to :stage, class_name: '::Crm::KanbanStage'
  belongs_to :contact, optional: true
  belongs_to :conversation, optional: true
  belongs_to :product, optional: true, class_name: '::Crm::Product'
  belongs_to :assignee, optional: true, class_name: 'User'
  belongs_to :last_message, optional: true, class_name: 'Message'

  has_many :actions, dependent: :destroy_async, class_name: '::Crm::KanbanAction', foreign_key: :card_id, inverse_of: :card
  has_many :activities, dependent: :destroy_async, class_name: '::Crm::KanbanActivity', foreign_key: :card_id, inverse_of: :card
  has_many :follow_up_schedules, dependent: :destroy_async, class_name: '::Crm::KanbanFollowUpSchedule', foreign_key: :card_id, inverse_of: :card

  validates :title, presence: true
  validates :budget_currency, presence: true
  validates :status, inclusion: { in: %w[open won lost archived] }
  validate :same_account

  before_validation :apply_defaults
  before_validation :sync_pipeline_from_stage
  before_save :stamp_terminal_status

  scope :active, -> { where.not(status: 'archived') }
  scope :ordered, -> { order(:position, updated_at: :desc) }
  scope :open_status, -> { where(status: 'open') }

  def stale_days
    return 0 if stage_changed_at.blank?

    ((Time.current - stage_changed_at) / 1.day).floor
  end

  def stale_level
    return 'none' if stage.stale_after_days.to_i.zero?
    return 'critical' if stale_days >= stage.stale_after_days * 2
    return 'stale' if stale_days >= stage.stale_after_days

    'fresh'
  end

  def next_open_activity
    activities.open_status.order(Arel.sql('due_at ASC NULLS LAST'), :created_at).first
  end

  private

  def apply_defaults
    self.stage_changed_at ||= Time.current
    self.last_activity_at ||= Time.current
    self.budget_currency = budget_currency.presence || 'BRL'
    self.status = status.presence || 'open'
    self.source = source.presence || 'manual'
  end

  def sync_pipeline_from_stage
    self.pipeline = stage.pipeline if stage.present?
  end

  def stamp_terminal_status
    self.won_at ||= Time.current if status_changed? && status == 'won'
    self.lost_at ||= Time.current if status_changed? && status == 'lost'
  end

  def same_account
    return if account_id.blank?

    errors.add(:pipeline, 'must belong to the same account') if pipeline.present? && pipeline.account_id != account_id
    errors.add(:stage, 'must belong to the same account') if stage.present? && stage.account_id != account_id
    errors.add(:contact, 'must belong to the same account') if contact.present? && contact.account_id != account_id
    errors.add(:conversation, 'must belong to the same account') if conversation.present? && conversation.account_id != account_id
    errors.add(:product, 'must belong to the same account') if product.present? && product.account_id != account_id
    errors.add(:assignee, 'must belong to the same account') if assignee.present? && !account.users.exists?(assignee.id)
    errors.add(:last_message, 'must belong to the same account') if last_message.present? && last_message.account_id != account_id
  end
end
