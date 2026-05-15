class Crm::Kanban::FollowUps::ScheduleCanceler
  def initialize(card:, reason:, data: {})
    @card = card
    @reason = reason
    @data = data
  end

  def perform
    card.follow_up_schedules.scheduled.find_each do |schedule|
      schedule.cancel!(reason: reason, data: data)
    end
  end

  private

  attr_reader :card, :reason, :data
end
