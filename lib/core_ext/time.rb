if RUBY_VERSION < '1.9'
  
  require 'date'
  require 'time'
  
  class Time
    def to_date
      Date.civil(self.year, self.month, self.day)
    end  
  end
  
end