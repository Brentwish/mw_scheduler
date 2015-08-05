require 'csv'
require 'date'

NAME = "brent"
days = [
  {:day => "MONDAY", :name => 1, :hours => 2 },
  {:day => "TUESDAY", :name => 3, :hours => 4 },
  {:day => "WEDNESDAY", :name => 5, :hours => 6 },
  {:day => "THURSDAY", :name => 7, :hours => 8 },
  {:day => "FRIDAY", :name => 9, :hours => 10 },
  {:day => "SATURDAY", :name => 11, :hours => 12 },
  {:day => "SUNDAY", :name => 13, :hours => 14 }]

schedule = CSV.read("july_27_2015.csv")

#Takes the schedule and returns an array
#that (hopefully) contains the two rows
#that the dates are on.
def get_biweek(schedule)
  a = []
  week_days = ["MONDAY",
               "TUESDAY",
               "WEDNESDAY",
               "THURSDAY",
               "FRIDAY",
               "SATURDAY",
               "SUNDAY"]
  schedule.each_with_index do |row, i|
    row = row.compact.map { |a| a.upcase }
    if row.all? { |word| week_days.include?(word) } && row != []
      a.push(i + 1)
    end
  end
  return a
end

#Takes a day and hour and formats it as a date
def get_date(day, hours)
  current_time = Time.new(2015, 7, 26) #Preset date for testing. Should be current time
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
  return Time.new(year, month, day, hours)
end

#takes the schedule, days, and a person and returns
#an array of work days that that name works on
def package_date_time(schedule, days, person)
  work_days = []
  biweek = get_biweek(schedule)
  week_1 = schedule[biweek[0]].compact.uniq
  week_2 = schedule[biweek[1]].compact.uniq

  schedule.each_with_index do |row, i|
    days.each_with_index do |day, j|
      date = ( i < biweek[1] ? week_1[j] : week_2[j] )
      day_name = day[:day]
      name = row[day[:name]]
      hours = row[day[:hours]]
      if name && hours && name.downcase.include?(person)
        work_days.push({
          :name => person,
          :date => get_date(date, hours)
        })
      end
    end
  end
  return work_days
end

puts package_date_time(schedule, days, NAME)
