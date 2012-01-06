
Dir[File.expand_path('commands/*',File.dirname(__FILE__))].each do |f|
  require f
end

module Todoer

  module CLI
  
    module Commands
    end
    
    def self.command(cmd, opts)
      begin
        c = Commands.const_get(cmd.to_s.capitalize)
      rescue NameError
        raise NameError, "Unknown command '#{cmd}'"
      end
      c.new(environment(opts))
    end
    
    def self.environment(opts)
      Environment.new(opts)
    end
    
  end
 
end