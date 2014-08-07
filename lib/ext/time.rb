# open up time class
class Time
  def beijing_time
    self.in_time_zone('beijing').localtime.to_s.split(/ \+/)[0]
  end
end
