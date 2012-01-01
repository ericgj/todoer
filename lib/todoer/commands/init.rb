
module Todoer
  module CLI
    module Commands
    
      class Init

        def initialize(env)
          Todoer.debug env.options.inspect
          proj = env.options.fetch( :project, [default_project] ).first
          ARGV.unshift 'add', proj
          @cmd = Todoer::CLI::Commands::Project.new(env)
        end
      
        def call
          @cmd.call
        end

        private
        
        def default_project
          File.basename(File.expand_path( ARGV.first || '.' ))
        end
        
      end
      
    end
  end
end