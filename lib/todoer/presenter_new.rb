require 'forwardable'

module Todoer

  class Presenter
  
    class << self

      def presenter_module
        @presenter_module ||= Module.new {
        
          def %(fmtstr)
          end
          
          def with_categories_and_scheduled_date
            "(#{categories_string}) #{self}" + 
            self.scheduled? ? " (schd #{self.scheduled_date.strftime(fmt)})" : ""
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
      
    extend Forwardable
    
    def_delegators :@todo, :category, :categories, :aggregate_categories,
                           :scheduled, :done, :due, :overdue, :started, :on, :on_today
                           
    def initialize(todo)
      @todo = todo
    end
    
    def tasks
      @tasks ||= @todo.tasks.map {|t| t.extend(self.class.presenter_module)}
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
<% (due | overdue | on_today).each do |task| %>
-  <%= task.with_categories_and_scheduled_date %> 
<% end %>

DUE TOMORROW
<% (due(Date.today + 1) | on(Date.today + 1)).each do |task| %>
-  <%= task.with_categories_and_scheduled_date %>
<% end %>

TODO
<% categories.each do |cats, tasks| %>
<%= cats.join(' ') %>:
  <% tasks.each do |task| %>
-  <%= task %>
  <% end %>
  
<% end %>
  
_____
  
  }.render(presenter)
  
end


__END__

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
  
  class CategoryPresenter < Presenter
  
    present_tasks do
      
      def to_s
        "(#{self.categories.join(' ')}) #{self.name}" +
        (self.dates.empty? ? "" : " (#{self.dates.map {|h,k| "#{h} #{k}"}.join('; ')})")
      end
    
    end
  end
  
  
  class TagPresenter < Presenter
  
    present_tasks do
    
      def to_s
        self.name +
        (self.tags.empty? ? "" : " (#{self.tags.to_a.join('; ')})")     
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
  categorized = Todoer::CategoryPresenter.new( todo )
  
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
  
  }.render(categorized, {:simple => simple})
  
end
