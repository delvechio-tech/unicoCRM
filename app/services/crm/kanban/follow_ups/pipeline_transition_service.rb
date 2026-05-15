class Crm::Kanban::FollowUps::PipelineTransitionService
  def initialize(card:, previous_pipeline_id:)
    @card = card
    @previous_pipeline_id = previous_pipeline_id
  end

  def perform
    return if previous_pipeline_id.blank? || previous_pipeline_id == card.pipeline_id

    Crm::Kanban::FollowUps::ScheduleCanceler.new(
      card: card,
      reason: 'pipeline_changed',
      data: {
        'from_pipeline_id' => previous_pipeline_id,
        'to_pipeline_id' => card.pipeline_id
      }
    ).perform
  end

  private

  attr_reader :card, :previous_pipeline_id
end
