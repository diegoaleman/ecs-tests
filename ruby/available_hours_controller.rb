class AvailableHoursController < ApiController
  def index
		render json: { hours: available_schedules }
  end
	
  private
  def week
    if params[:from] && params[:to]
      Time.zone.parse(params[:from])..Time.zone.parse(params[:to])
    else
      Time.current.beginning_of_week..Time.current.end_of_week
    end
  end

  def account
    @account ||= Account.find_by!(username: params[:account])
  end

  def consultation_schedules
    ConsultationSchedule.where(starts_at: week, account: account)
  end

	def hour_parser(time)
		CalendarTimeCalculation.hour_parser(time)
	end

	def minute_parser(time)
		CalendarTimeCalculation.minute_parser(time)
	end

	def available_schedules
		consultation_duration = account
			.configuration['schedule']['consultation_duration']

		schedules = account_schedules(consultation_duration.minutes)

		consultation_schedules.each do |schedule|
			day = schedule.starts_at.strftime('%a').downcase
			next if schedules[day].empty?
			rounded_times = CalendarTimeCalculation
				.round_times(account, schedule, consultation_duration, day)

			current_parsed_time = hour_parser(rounded_times.first)
			end_schedule_parsed = hour_parser(rounded_times.last)

			# Travel and block each slot from current to end
			until current_parsed_time >= end_schedule_parsed
				schedule_time_parsed = minute_parser(current_parsed_time)

				index = schedules[day].index(schedule_time_parsed)
				schedules[day].delete_at(index) if index # Make sure the slot exists

				current_parsed_time += consultation_duration
			end

			last_val = schedules[day].index(rounded_times.last)
			schedule_ends = hour_parser(schedule.ends_at.strftime('%H:%M'))
			# If Schedule ends after schedule ends parsed, delete the last slot
			if schedule_ends > end_schedule_parsed && last_val
				schedules[day].delete_at(last_val)
			end
		end

		return schedules
	end

  def account_schedules(duration)
    schedule = account.configuration['schedule'].except('consultation_duration')
    # ex: schedule = { "mon" => ["8:00-12:00", "15:20-20:15"] }
    result = {
      'mon' => [],
      'tue' => [],
      'wed' => [],
      'thu' => [],
      'fri' => [],
      'sat' => [],
      'sun' => []
    }

    schedule.each do |day, _value|
      schedule[day].each do |range|
        range_time = range.split('-').map { |time| Time.zone.parse(time) }

        current_range = range_time.first

        until current_range >= range_time.last
          result[day].push(current_range.to_formatted_s(:time))
          current_range += duration
        end
      end

      result[day].sort!
    end
    result
  end
end
