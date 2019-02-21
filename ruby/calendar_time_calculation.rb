module CalendarTimeCalculation
  def self.hour_parser(time = '12:00')
    splited_time = time.split(':')
    splited_time[0].to_i * 60 + splited_time[1].to_i
  end

  def self.minute_parser(time = 120)
    minutes = time % 60
    minutes = '00' if minutes.eql?(0)

    hour = time / 60
    hour = "0#{hour}" if hour < 10
    "#{hour}:#{minutes}"
  end

  def self.round_times(account, schedule, consultation_duration, day)
    times = [
      hour_parser(schedule.starts_at.strftime('%H:%M')),
      hour_parser(schedule.ends_at.strftime('%H:%M'))
    ]

    schedule_ranges = day_schedule_ranges(account, day)

    times.map do |time|
      nearest_schedule = nearest_schedule(time, schedule_ranges)
      floor(nearest_schedule, time, consultation_duration)
    end
  end

  def self.floor(range_start, consultation_time, duration)
    diff = consultation_time - range_start
    diff2 = (diff.abs % duration)

    if diff >= 0
      minute_parser(consultation_time - diff2)
    # Its not on range
    else
      minute_parser(consultation_time - (duration - diff2))
    end
  end

  def self.nearest_schedule(consultation_time = 900, schedules = [[]])
    closest = 24 * 60
    nearest = nil
    schedules.each do |schedule|
      return schedule[0] if consultation_time.between?(schedule[0], schedule[1])

      diff = (schedule[0] - consultation_time).abs
      if diff < closest
        closest = diff
        nearest = schedule[0]
      end
    end
    nearest
  end

  def self.day_schedule_ranges(account, day)
    ranges = account
			.configuration['schedule'][day].map { |range| range.split('-') }

    results = []

    ranges.each do |range|
      results.push(
        range.map do |hour|
          hour_parser(hour)
        end
      )
    end
    results
  end
end
