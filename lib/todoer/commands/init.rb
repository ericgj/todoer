
module Todoer
  module CLI
    module Commands
    
      class Init

        def initialize(env)
          @env = env
          proj = environment_project || default_project
          ARGV.unshift 'add', proj
          @cmd = Todoer::CLI::Commands::Project.new(env)
        end
      
        # Note does not yet initialize the todo file
        # which probably should be passed off to the adapter to do
        # or just leave it alone
        def call
          @cmd.call
        end

        private
        
        def environment_project
          @env.options[:projects].first
        end
        
        def default_project
          File.basename(File.expand_path( ARGV.first || '.' ))
        end
        
      end
      
    end
  end
end