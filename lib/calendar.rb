#The Calendar keeps track of what date and time it is in the game, based on UNIX time from a given epoch time (year, day, and hour zero of the world).
#
#Currently, this is 1 actual hour = 1 day, 24 days = 1 month, 12 months = 1 year.
class Calendar
  StartTime = 1205971200
  MONTH_NAMES = ["First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth", "Ninth", "Tenth", "Eleventh", "Twelfth"]
  attr_reader :hour, :day, :month, :year

  def initialize
    @last_hour = 0
    @last_day = nil
    @last_year = nil
    self.tick(true)
  end

  #Called to update the calendar.
  def tick(init = false)
    @time = Time.now.to_i - StartTime
    @hour = @time / 60 % 60
    @day = @time / 60 / 60 % 24 + 1
    @month = @time / 60 / 60 / 24 % 12
    @year = @time / 60 / 60 / 24 / 12

    unless init
      if @last_hour != @hour
        msg = time_change
        $manager.alert_all msg if msg
      end
      if @last_day != @day
        $manager.alert_all day_change
      end
      if @last_year != @year
        $manager.alert_all year_change
      end
    end

    @last_day = @day
    @last_hour = @hour
    @last_year = @year
  end

  #Returns the Calendar#time_of_day for a given timestamp.
  def time_at(timestamp = Time.now.to_i)
    hour, rest = convert(timestamp)
    time_of_day hour
  end

  #Returns a simple date for the given timestamp.
  def date_at(timestamp = Time.now.to_i)
    hour, day, month, year = convert(timestamp)
    "#{ordinal_day(day)} of #{MONTH_NAMES[month]}, #{year}"
  end

  #Returns a String representation of the current time.
  def time
    "It is #{time_of_day} in Ahln."
  end

  #Returns a String representation of the current date.
  def date
    "Today is the #{ordinal_day} day of the #{MONTH_NAMES[@month]} Month in the year #@year."
  end

  def night?
    not day?
  end

  def day?
    @hour >= 15 and @hour < 44
  end

  #Prints out a nice version of the in-game date and time.
  def to_s
    "It is currently #{time_of_day} on the #{ordinal_day} day of the #{MONTH_NAMES[@month]} Month in the year #@year."
  end

  private

  #Message when the year changes.
  def year_change
    "Happy new year! It is now #{@year} years past an arbitrary date!"
  end

  #Message when the day changes.
  def day_change
    "As midnight passes, the day rolls over to the #{ordinal_day} of the #{MONTH_NAMES[@month]} Month."
  end

  #Message when the hour changes.
  def time_change
    case @hour
    when 0
      "An eerie feeling lies over the land as the darkness of midnight stands absolute."
    when 10
      "The dark shadows begin to turn grey as morning approaches."
    when 15
      "As dawn breaks, the sun spreads golden hues across the sky."
    when 30
      "The sun stands high in the sky, marking the middle of the day."
    when 45
      "The heat of the day begins to subside as the sun touches the horizon."
    when 50
      "The stars glimmer into view as darkness fully claims the sky."
    else
      nil
    end

  end

  #Returns the ordinal day.
  def ordinal_day(day = @day)
    day.to_s + case day.to_s
        when '11', '12', '13'
          'th'
        when /1$/
          'st'
        when /2$/
          'nd'
        when /3$/
          'rd'
        when /(4|5|6|7|8|9|0)$/
          'th'
        else
          ''
        end
  end

  #Returns the time of day based on the current time.
  def time_of_day(hour = @hour)
    case hour
    when 0..3
      "midnight"
    when 3..10
      "after midnight"
    when 10..15
      "approaching dawn"
    when 15..16
      "dawn"
    when 16..17
      "early morning"
    when 17..20
      "morning"
    when 20..25
      "late morning"
    when 25..30
      "almost noon"
    when 30..32
      "noon"
    when 32..30
      "afternoon"
    when 30..40
      "late afternoon"
    when 40..44
      "nearing dusk"
    when 44..46
      "dusk"
    when 46..55
      "nighttime"
    when 55..60
      "nearly midnight"
    else
      "uh oh"
    end
  end

  #Converts a timestamp to hour, day, month, year (returned as an array).
  def convert(timestamp)
    time = timestamp - StartTime
    hour = time / 60 % 60
    day = time / 60 / 60 % 24 + 1
    month = time / 60 / 60 / 24 % 12
    year = time / 60 / 60 / 24 / 12

    return hour, day, month, year
  end
end

