class Crm::KanbanWebhook < ApplicationRecord
  self.table_name = 'crm_kanban_webhooks'

  EVENTS = %w[
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
  belongs_to :pipeline, optional: true, class_name: '::Crm::KanbanPipeline'

  validates :name, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validate :same_account

  scope :active, -> { where(active: true) }

  def deliver?(event_name, event_pipeline_id)
    return false unless active?
    return false if pipeline_id.present? && pipeline_id != event_pipeline_id

    events.blank? || events.include?(event_name)
  end

  private

  def same_account
    return if pipeline.blank?
    return if pipeline.account_id == account_id

    errors.add(:pipeline, 'must belong to the same account')
  end
end
