class Crm::KanbanFollowUpSchedule < ApplicationRecord
  self.table_name = 'crm_kanban_follow_up_schedules'

  SOURCES = %w[cadence customer_requested ai_negotiated manual_override long_term_reactivation].freeze
  STATUSES = %w[scheduled processing sent canceled failed].freeze

  belongs_to :account
  belongs_to :pipeline, class_name: '::Crm::KanbanPipeline'
  belongs_to :card, class_name: '::Crm::KanbanCard'
  belongs_to :contact, optional: true
  belongs_to :conversation, optional: true

  has_many :events, dependent: :destroy_async, class_name: '::Crm::KanbanFollowUpEvent', foreign_key: :schedule_id, inverse_of: :schedule

  validates :source, inclusion: { in: SOURCES }
  validates :status, inclusion: { in: STATUSES }
  validates :scheduled_for, presence: true
  validate :same_account

  scope :scheduled, -> { where(status: 'scheduled') }
  scope :due, -> { scheduled.where('scheduled_for <= ?', Time.current) }
  scope :ready_to_send, -> { where.not(generated_message: [nil, '']) }

  def cancel!(reason:, data: {})
    update!(status: 'canceled', reason: reason, canceled_at: Time.current)
    events.create!(account: account, card: card, event_type: 'canceled', data: data.merge('reason' => reason))
  end

  private

  def same_account
    return if account_id.blank?

    errors.add(:pipeline, 'must belong to the same account') if pipeline.present? && pipeline.account_id != account_id
    errors.add(:card, 'must belong to the same account') if card.present? && card.account_id != account_id
    errors.add(:contact, 'must belong to the same account') if contact.present? && contact.account_id != account_id
    errors.add(:conversation, 'must belong to the same account') if conversation.present? && conversation.account_id != account_id
  end
end
