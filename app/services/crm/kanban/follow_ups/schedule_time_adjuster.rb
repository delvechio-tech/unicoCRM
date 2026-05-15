class Crm::Kanban::FollowUps::ScheduleTimeAdjuster
  def initialize(settings:, candidate:)
    @settings = settings.to_h
    @candidate = candidate
  end

  def perform
    return candidate unless business_hours_enabled?

    adjusted = candidate
    loop do
      adjusted = move_to_next_business_day(adjusted) unless business_day?(adjusted)
      return adjusted.change(hour: business_start.hour, min: business_start.min) if adjusted < business_start_at(adjusted)
      return adjusted if adjusted <= business_end_at(adjusted)

      adjusted = move_to_next_business_day(adjusted + 1.day)
    end
  end

  private

  attr_reader :settings, :candidate

  def business_hours_enabled?
    settings['business_hours_enabled'] == true &&
      settings['business_start'].present? &&
      settings['business_end'].present?
  end

  def business_day?(time)
    allowed_days.include?(time.strftime('%a').downcase[0, 3])
  end

  def move_to_next_business_day(time)
    candidate_time = time
    candidate_time += 1.day until business_day?(candidate_time)
    candidate_time.change(hour: business_start.hour, min: business_start.min)
  end

  def allowed_days
    Array(settings['business_days']).presence || %w[mon tue wed thu fri]
  end

  def business_start
    @business_start ||= Time.zone.parse(settings['business_start'])
  end

  def business_end
    @business_end ||= Time.zone.parse(settings['business_end'])
  end

  def business_start_at(time)
    time.change(hour: business_start.hour, min: business_start.min)
  end

  def business_end_at(time)
    time.change(hour: business_end.hour, min: business_end.min)
  end
end
