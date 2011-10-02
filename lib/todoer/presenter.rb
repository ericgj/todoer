
module Todoer

  class Presenter
    
    class << self
      
      def presenters
        @presenters ||= Module.new {
          def to_s
            name
          end
        }
      end
      
      def present_tasks(&blk)
        @presenters = Module.new(&blk)
      end
      
    end
    
    def initialize(todo)
      @todo = todo
    end
    
    def tasks
      @tasks ||= @todo.tasks.each(&self.method(:extend_task))
    end
      
    def scheduled
      tasks.select {|t| t.scheduled? }
    end
    
    def done
      tasks.select {|t| t.done?}
    end
    
    def due(dt=Date.today)
      tasks.select {|t| t.due?(dt)}
    end
    
    def overdue(dt=Date.today)
      tasks.select {|t| t.overdue?(dt)}
    end
    
    def on(dt=Date.today)
      tasks.select {|t| t.on?(dt)}
    end
    
    def on_today; on; end
    
    def categories
      tasks.inject(Hash.new {|h,k| h[k]=[]}) {|memo, task|
        memo[task.categories] << extend_task(task)
        memo
      }
    end
    
    def aggregate_categories
      tasks.inject({}) {|memo,task|
        trav = memo
        task.categories.each do |cat| 
          trav = ( trav[cat] ||= {} )
        end
        (trav['tasks'] ||= []) << extend_task(task)
        memo
      }
    end
    
    private
    
    def extend_task(task)
      task.extend(self.class.presenters)
      task
    end
    
  end
  
  
  class DatePresenter < Presenter
    
    present_tasks do
      
      def to_s
        self.name +
        (self.dates.empty? ? "" : " (#{self.dates.map {|h,k| "#{h} #{k}"}.join('; ')})")
      end
      
    end
    
  end
  
end
  
if $0 == __FILE__

  require File.expand_path('todo',File.dirname(__FILE__))

  require 'erubis'
  require 'tilt'
  
  todo = Todoer.parse('~/.todo')
  date = Todoer::DatePresenter.new( todo )
  simple = Todoer::Presenter.new( todo )
  
  template = Tilt[:erubis]
  
  puts template.new { <<_____
  
DUE OR OVERDUE
<% (due | overdue | on_today).each do |task| %>
-  <%= task %>
<% end %>

DUE TOMORROW
<% (due(Date.today + 1) | on(Date.today + 1)).each do |task| %>
-  <%= task %>
<% end %>

TODO
<% simple.categories.each do |cats, tasks| %>
<%= cats.join(' ') %>:
  <% tasks.each do |task| %>
-  <%= task %>
  <% end %>
  
<% end %>
  
_____
  
  }.render(date, {:simple => simple})
  
end
