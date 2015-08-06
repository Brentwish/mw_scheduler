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
@person = "trevor"

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
  hours = parse_hours(hours)
  start_time = DateTime.new(year, month, day, hours[0], 0, 0, '-7').to_s
  end_time = DateTime.new(year, month, day, hours[1], 0, 0, '-7').to_s
  return { :start => start_time, :end => end_time }
end

def parse_hours(hours)
  hours = hours.split('-')
  hours.map { |str| str.gsub!(/\s+/, "") } #removes all white space
#an attempt to translate something like "5:30" to "5.5"
#  hours.each do |time|
#    if time.include?(":")
#      time = time.split(":")
#      time[1] = time[1].to_f / 60
#      time = time[0].to_f + time[1]
#    end
#  end
  hours[0] = (hours[0].to_i > 6 ? hours[0].to_i : hours[0].to_i + 12) #adjusts hours to a 24 hour clock. Pivots at 6
  hours[1] = (hours[1].downcase.include?("close") ? 20 : hours[1].to_i + 12) #sets "close" to be 8pm
  print hours
  print "\n"
  return hours
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

get_work_days
