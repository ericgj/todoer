# eventually move this into main Todo source file or maybe Todoer file
# note it depends on lib/adapters

require File.expand_path('adapters', File.dirname(__FILE__))

module Todoer

  class << self

    attr_accessor :default_adapter
    
    def default_adapter; @default_adapter ||= :yaml; end    
    def todo; @todo ||= Todo.new; end
    def sources; @sources ||= []; end
    
    def configure
      yield todo
    end
    
    def load_environment(env)
      reset
      load env.sources[:global] if env.sources[:global]
      env.project_sources.each do |(key, file)|
        load(file, :categories => key)
      end      
    end
    
    # Options
    #   +adapter+::    name of the adapter for file type
    #   +categories+:: project or categories array for this todo list, if needed by adapter
    # Any other option is adapter-specific
    def load(file, opts={})
      debug "Loading #{file} #{opts.inspect}"
      adapter_for(file, opts.delete(:adapter)).tap do |a| 
        debug "with adapter #{a}"
      end.new(file, opts).each do |entry|
        self.todo << entry
      end
      sources << file
    end
    
    def reset
      @todo = nil; @sources = nil
    end
    
    def adapter_for(file, adapter=nil)
      return Adapters.get(adapter) if adapter
      ext = File.extname(file).tr('.','')
      ext = File.basename(file).tr('.','') if ext.empty? && /^\./ =~ File.basename(file)
      if ext.empty?
        Adapters.get(default_adapter) 
      else 
        Adapters.get(ext.downcase.to_sym)
      end
    end
        
  end
  
end