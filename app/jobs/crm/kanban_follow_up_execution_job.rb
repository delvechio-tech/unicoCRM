class Crm::KanbanFollowUpExecutionJob < ApplicationJob
  queue_as :medium

  def perform(schedule_id)
    schedule = Crm::KanbanFollowUpSchedule.includes(:card, :conversation).find_by(id: schedule_id)
    return if schedule.blank?

    Crm::Kanban::FollowUps::ExecutionService.new(schedule: schedule).perform
  end
end
