class Crm::KanbanFollowUpDispatchJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Crm::KanbanFollowUpSchedule.due.find_each do |schedule|
      if schedule.generated_message.blank?
        Crm::KanbanFollowUpGenerationJob.perform_later(schedule.id)
      elsif ready_for_execution?(schedule)
        Crm::KanbanFollowUpExecutionJob.perform_later(schedule.id)
      end
    end
  end

  private

  def ready_for_execution?(schedule)
    schedule.pipeline.settings.to_h.dig('follow_up_settings', 'delivery_mode') != 'review_before_send' ||
      schedule.metadata.to_h['review_state'] == 'approved'
  end
end
