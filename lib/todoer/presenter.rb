# uncomment to run tests at bottom
#require File.expand_path('query_collection',File.dirname(__FILE__))

module Todoer

  class Presenter < QueryCollection
  
    class << self

      def presenter_module
        @presenter_module ||= Module.new {
        
          def %(fmtstr)
          end
          
          def with_categories_and_scheduled_date(fmt='%Y-%m-%d')
            "(#{categories_string}) #{self}" + 
            (self.scheduled? ? " (schd #{self.scheduled_date.strftime(fmt)})" : "")
          end
          
          def with_categories
            "(#{categories_string}) #{self}"
          end
          
          def with_dates(fmt='%Y-%m-%d')
            "#{self}" + 
            self.dates.empty? ? "" : " (#{dates_string(fmt)})"
          end
          
          def with_scheduled_date(fmt='%Y-%m-%d')
            "#{self}" + 
            self.scheduled? ? " (schd #{self.scheduled_date.strftime(fmt)})" : ""
          end

          def categories_string(delim=' ')
            self.categories.join(delim)
          end
          
          def tags_string(delim=' ')
            self.tags.join(delim)
          end
          
          def dates_string(fmt='%Y-%m-%d')
            self.dates.map {|h,k| "#{h} #{k.strftime(fmt)}"}.join('; ')
          end
        }
      end

      def presentations(&blk)
        @presenter_module = Module.new(&blk)
      end

    end   

    def initialize(todo)
      super todo.tasks
    end
    
    def each
      super do |t| yield t.extend(self.class.presenter_module) end
    end

    def [](*cats)
      self.and {|t| t.categories_like?(*cats)}
    end
    
    def categories
      all.inject(Hash.new {|h,k| h[k]=[]}) {|memo, task|
        memo[task.categories] << task
        memo
      }
    end
    
    def aggregate_categories
      all.inject({}) {|memo,task|
        trav = memo
        task.categories.each do |cat| 
          trav = ( trav[cat] ||= {} )
        end
        (trav['tasks'] ||= []) << task
        memo
      }
    end
    
  end
  
end


if $0 == __FILE__

  require File.expand_path('markup_string',File.dirname(__FILE__))
  require File.expand_path('todo',File.dirname(__FILE__))

  require 'erubis'
  require 'tilt'
  
  todo = Todoer.parse('~/.todo')
  presenter = Todoer::Presenter.new(todo)
  
  erb = Tilt[:erubis]
  
  puts erb.new { <<_____
  
DUE OR OVERDUE
<% (where(&:due?).or(&:overdue?).or(&:on_today?)).each do |task| %>
-  <%= task.with_categories_and_scheduled_date %> 
<% end %>

DUE TOMORROW
<% (where(&:due_tomorrow?).or(&:on_tomorrow?)).each do |task| %>
-  <%= task.with_categories_and_scheduled_date %>
<% end %>

UNSCHEDULED
<% (where(:not, &:scheduled?)).each do |task| %>
-  <%= task.with_categories %>
<% end %>

TODO
<% where.categories.each do |cats, tasks| %>
<%= cats.join(' ') %>:
  <% tasks.each do |task| %>
-  <%= task %>
  <% end %>
  
<% end %>
  
_____
  
  }.render(presenter)
  
end
