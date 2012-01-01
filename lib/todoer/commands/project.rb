

module Todoer
  module CLI
    module Commands
    
      class Project
      
        def initialize(env)
          #@env = env
          @env = Todoer::Environment.blank
        end
        
        def call
          subcmd = ARGV.shift
          if subcmd
            call_subcommand(subcmd, *ARGV)
          else
            call_subcommand('add')
          end
        end
        
        def add(proj=File.basename(Dir.pwd), path='.')
          path = File.join(path, '.todo') if File.directory?(path)
          @env.add_source proj, path
          @env.save_sources!
        end
        
        private
        
        def call_subcommand(cmd, *args)
          self.send(cmd.to_s.downcase, *args)
        rescue NoMethodError
          raise NoMethodError, "Unknown project command '#{cmd.to_s.downcase}'"
        end
        
      end
      
    end
  end
end
