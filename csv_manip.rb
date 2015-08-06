require './calendar_event_creator.rb'
require 'csv'
require 'date'

DAYS = [
  {:day => "MONDAY", :name => 1, :hours => 2 },
  {:day => "TUESDAY", :name => 3, :hours => 4 },
  {:day => "WEDNESDAY", :name => 5, :hours => 6 },
  {:day => "THURSDAY", :name => 7, :hours => 8 },
  {:day => "FRIDAY", :name => 9, :hours => 10 },
  {:day => "SATURDAY", :name => 11, :hours => 12 },
  {:day => "SUNDAY", :name => 13, :hours => 14 }]

@schedule = CSV.read("july_27_2015.csv")
@person = "brent"

#Takes the schedule and returns an array
#that (hopefully) contains the two rows
#that the dates are on.
def get_biweek()
  a = []
  week_days = DAYS.map { |day| day[:day] }
  @schedule.each_with_index do |row, i|
    row = row.compact.map { |a| a.upcase }
    if row.all? { |word| week_days.include?(word) } && row != []
      a.push(i + 1)
    end
  end
  return a
end

#Takes a day and hour and formats it as a date
def get_date(day, hours)
  current_time = Time.new(2015, 7, 12) #Preset date for testing. Should be current time
  if day.to_i > current_time.day
    month = current_time.month
    year = current_time.year
  else
    if current_time.month + 1 > 12
      month = 1
      year = current_time.year + 1
    else
      month = current_time.month + 1
      year = current_time.year
    end
  end
  year = year.to_i
  month = month.to_i
  day = day.to_i
  hours = hours.split('-')
  hours.map { |str| str.gsub!(/\s+/, "") } #removes all white space
  hours[0] = ((hours[0].to_i != 12 && hours[0].to_i > 6) ? hours[0] + "am" : hours[0] + "pm") #adjusts hours to a 24 hour clock. Pivots at 6
  hours[1] = (hours[1].downcase.include?("close") ? "8pm" : hours[1] + "pm") #sets "close" to be 8pm
  hours.map! { |time| DateTime.parse(time).strftime("%H:%M:%S") }
  start_time = DateTime.parse("#{year}-" + sprintf("%02d", month) + "-" + sprintf("%02d", day) + "T#{hours[0]}" + "-0700")
  end_time = DateTime.parse("#{year}-" + sprintf("%02d", month) + "-" + sprintf("%02d", day) + "T#{hours[1]}" + "-0700")
  return { :start => start_time, :end => end_time }
end

#takes the schedule, days, and a person and returns
#an array of work days that that name works on
def get_work_days
  work_days = []
  biweek = get_biweek
  week_1 = @schedule[biweek[0]].compact.uniq
  week_2 = @schedule[biweek[1]].compact.uniq

  @schedule.each_with_index do |row, i|
    DAYS.each_with_index do |day, j|
      date = ( i < biweek[1] ? week_1[j] : week_2[j] )
      day_name = day[:day]
      name = row[day[:name]]
      hours = row[day[:hours]]
      if name && hours && name.downcase.include?(@person.downcase)
        work_days.push({
          :name => @person,
          :date => get_date(date, hours)
        })
      end
    end
  end
  return work_days
end

def set_schedule
  work_days = get_work_days
  work_days.each do |day|
    start_time = day[:date][:start]
    end_time = day[:date][:end]
    CalendarEventCreator.create_event(start_time, end_time)
  end
  CalendarEventCreator.fetch_ten_events
end

def main
  CalendarEventCreator.init
  set_schedule
  puts get_work_days
end
main
