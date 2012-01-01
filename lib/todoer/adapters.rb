module Todoer
  
  AdapterError = Class.new(StandardError)
  
  module Adapters
  
    ADAPTER_MAP = { 'yaml' => 'yaml',
                    'yml'  => 'yaml',
                    'todo' => 'todo'
                  }
                  
    def self.get(name)
      name = name.to_s.downcase
      self.const_get(ADAPTER_MAP[name].capitalize)
    rescue NameError
      require default_adapter_source(name)
      self.const_get(ADAPTER_MAP[name].capitalize)
    end
    
    def self.default_adapter_source(name)
      File.expand_path("adapters/#{ADAPTER_MAP[name]}",
                       File.dirname(__FILE__)
                      )
    end
    
  end
  
end