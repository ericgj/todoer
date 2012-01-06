require 'yaml'

module Todoer
  module CLI
    module Commands
    
      class Project
      
        # note: global commandline options are ignored except for list
        def initialize(env)
          @env = env
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
          path = File.join(path, File.basename(@env.local_todo)) if File.directory?(path)
          @env.add_source proj, path
          @env.save_sources!
        end
        
        def rm(proj=File.basename(Dir.pwd))
          @env.rm_source proj
          @env.save_sources!
        end
        
        def list
          $stdout.write YAML.dump(@env.sources)
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
