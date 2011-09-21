
module Todoer

  # methods for extracting markup from String

  module MarkupString

    REGEXP_TAG = /\=(\w*)/
    REGEXP_NAME = /\@(\w+)/
    REGEXP_TIME = /\~(\d{1,2}[hm])(\d{1,2}m)?/
    REGEXP_DATE = /(due|start|done|on)\s+([A-Za-z0-9\-\/]+)/
    
    def tags; @tags ||= []; end
    def persons; @persons ||= []; end
    def dates; @dates ||= {}; end
    def time; @time ||= nil; end
    
    def extract_markup!
      extract_tags!
      extract_persons!
      extract_dates!
      extract_time!
    end
    
    def extract_tags!
      @tags = extract_and_gsub!(REGEXP_TAG)
    end
    
    def extract_persons!
      @persons = extract_and_gsub!(REGEXP_NAME)
    end

    def extract_dates!
      dates = extract_from_scan(REGEXP_DATE)
      @dates = Hash[*dates].inject({}) do |memo,(k,v)| 
        if dt = ( Date.parse(v) rescue nil )
          memo[k] = dt
        end
        memo
      end
    end
    
    def extract_time!
      times = extract_from_scan(REGEXP_TIME)
      @time = times.inject(nil) do |sum, time| 
        case time
        when NilClass
          sum
        when /(\d+)m$/
          sum ||= 0; sum += $1.to_i
        when /(\d+)h$/
          sum ||=0;  sum += $1.to_i * 60
        end
      end
    end
      
    private
    
    def extract_and_gsub!(rexp)
      extracts = []
      self.gsub!(rexp) do
        extracts += $~[1..-1]
        $~[1..-1].compact.join('')
      end
      extracts
    end
    
    def extract_and_remove!(rexp)
      extracts = []
      self.gsub!(rexp) do
        extracts += $~[1..-1]
        ''
      end
      extracts
    end
    
    def extract_from_scan(rexp)
      extracts = []
      self.scan(rexp) do
        extracts += $~[1..-1]
      end
      extracts
    end
    
  end

end