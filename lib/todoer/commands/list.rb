require 'erubis'
require 'tilt'

module Todoer
  module CLI
    module Commands
    
      class List
      
        DEFAULT_TEMPLATE = <<-_____
---
<%= 'Showing: ' + ARGV.join(' ') %>
<%= (["Sources:"] + Todoer.sources).join("\n-  ") %> 
---
<% where[*ARGV].categories.each do |(cats, tasks)| %>
<%= cats.join(' ') %>:
  <% tasks.each do |task| %>
-  <%= task %>
  <% end %>  
<% end %>
_____

        def presenter
          @presenter ||= Todoer::Presenter.new(Todoer.todo)
        end
        
        def template(tmpl)
          @template = Tilt[:erubis].new { tmpl }
        end

        def initialize(env)
          Todoer.load_environment(env)
        end
        
        # Note: define Trollop options here if needed; or simply use ARGV
        def call
          # TODO: parse :template option
          tmpl = DEFAULT_TEMPLATE
          ARGV.push '*'
          puts template(tmpl).render(presenter)          
        end
        
      end
      
    end
  end
end
