module Todoer
  
  AdapterError = Class.new(StandardError)
  
  module Adapters
  
    def self.get(name)
      require File.expand_path("adapters/#{name.to_s.downcase}", File.dirname(__FILE__))
      self.const_get("#{name.to_s.capitalize}")
    end
    
  end
  
end