class Crm::KanbanFollowUpGenerationJob < ApplicationJob
  queue_as :medium

  def perform(schedule_id)
    schedule = Crm::KanbanFollowUpSchedule.includes(:account, :pipeline, :card, :conversation).find_by(id: schedule_id)
    return if schedule.blank?

    Crm::Kanban::FollowUps::GenerationService.new(schedule: schedule).perform
  end
end
