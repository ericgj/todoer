# Simple parser for ~/.todo file
# Format is like
#
#   + [Tue Sep 20 12:10:13 EDT 2011] personal, walk the dog ~20m
#   + [Tue Sep 20 12:10:50 EDT 2011] freelance general, take photo with @thomas
#   * [Tue Sep 20 12:10:50 EDT 2011] freelance general, take photo with @elisa
#   - [Tue Sep 20 12:13:00 EDT 2011] freelance general, take photo
#   
# + == added tasks
# - == finished tasks
# * == changed tasks (doesn't quite work yet)
#
# The description is split into two parts; anything before the first comma is
# treated as a hierarchy of categories, anything after is the task description
#
# More features are planned such as extracting @-tags (@thomas, @elisa above)
# and time estimates (~15m) from the strings
#
# Note tasks are matched on the beginning of the description; so the finished
# task 'freelance general, take photo' matches the previous
#      'freelance general, take photo with @elisa'
#
# The ~/.todo file itself is the product of a simple bash one-liners.
#

# Un-comment this line to run the basic usage tests at bottom:
#require File.expand_path('markup_string', File.dirname(__FILE__))

require 'time'
require 'yaml'
require 'set'
require 'forwardable'

module Todoer

  def self.parse(file, &config)
    lines = []
    File.open(File.expand_path(file)) {|f| lines = f.readlines }
    Todo.parse lines, &config
  end
  
  class Todo
    
    def self.parse(lines, &config)
      new *lines.map {|line| LogEntry.parse(line) }.compact, &config
    end
    
    attr_accessor :tasks
    
    # todo.mark_done = 'done'   #>> deleted tasks are instead tagged 'done'
    attr_accessor :mark_done
    
    def initialize(*entries)
      @tasks = []
      yield self if block_given?
      entries.sort_by(&:logtime).each do |e|
        if e.add?; add e.task, e.logtime, e.categories; end
        if e.sub?; sub e.task, e.logtime, e.categories; end
      end
    end
     
    def add(task, timestamp, categories=[])
      @tasks << Task.new(task,timestamp,categories)
    end

    def sub(task, timestamp, categories=[])
      task = Task.new(task,timestamp,categories)
      if tag = self.mark_done then
        @tasks.select {|t| task == t}.each do |t|
          t.tag! tag
        end
      else
        @tasks.delete_if {|t| task == t}
      end
    end
         
    def category(*cats)
      tasks.select {|t| t.categories_like?(*cats)}
    end
    alias [] category
    
    
    class Task
      extend Forwardable
      
      attr_reader :categories, :timestamp, :persons, :dates, :time
      attr_accessor :name

      def_delegators :@name, :persons, :dates, :time
      def tags; @tags + @name.tags; end
      
      def initialize(task, timestamp, categories=[])
        @name, @timestamp, @categories = task, timestamp, categories
        @tags = Set.new
        @name.extend(Todoer::MarkupString)
        @name.current_date = self.timestamp.to_date
        @name.extract_markup!
      end

      def recategorize!(*cats)
        @categories = cats
      end
       
      def categorize!(cat)
        @categories.pop
        @categories << cat
      end
       
      def tag!(t)
        @tags << t
      end
       
      def categories_like?(*cats)
        if cats.last == '*'
          cats_d = cats.dup; cats_d.pop
          cats_d.empty? or categories[0...cats_d.size] == cats_d
        else
          categories == cats
        end          
      end
       
      def due_date; self.dates['due']; end
      def on_date; self.dates['on']; end
      def start_date; self.dates['start']; end
      def done_date; self.dates['done']; end
      def scheduled_date; on_date || due_date; end

      def scheduled?
        !!self.dates['on'] || self.dates['due']
      end

      def done?
        tags.include?('done')
      end

      def on?(dt=Date.today)
        on = self.dates['on']
        on and on == dt
      end      
      def on_today?; self.on?; end
      def on_tomorrow?; self.on?(Date.today + 1); end

      def due?(dt=Date.today)
        due = self.dates['due']
        due and due == dt
      end
      def due_today?; self.due?; end
      def due_tomorrow?; self.due?(Date.today + 1); end

      def overdue?(dt=Date.today)
        due = self.dates['due']
        on = self.dates['on']
        (due and due < dt) or (on and on < dt)
      end
           
      def started?
        !!self.dates['start']
      end

      def to_s; self.name; end

      # hacky, but how else?
      def inspect
        xtras  = [:tags, :persons, :dates, :time].inject({}) {|memo, meth|
          memo[meth] = self.send(meth).inspect
          memo
        }       
        super.gsub(/>$/, 
          ', ' + xtras.map {|h,k| "(delegated) #{h}=#{k}"}.join(', ') + '>'
        )
      end

      def ==(other)
        (self.categories == other.categories) and
        (/^#{Regexp.escape(self.name)}/ =~ other.name)
      end
      
    end

    class LogEntry
      attr_reader :action, :logtime, :task, :categories

      def self.parse(line)
        return unless /^(\+|\-|\*)\s\[(.*)\]\s([^,]+),\s*(.*)$/ =~ line
        new $1, $2, $3, $4
      end

      def initialize(action,logtime,categories,task)
        @action = action
        @logtime = Time.parse(logtime)
        @categories = categories.split(' ')
        @task = task
      end
      
      def add?; @action == '+'; end
      def sub?; @action == '-'; end

    end

  end

end
