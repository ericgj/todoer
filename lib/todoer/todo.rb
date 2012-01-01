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

  #@deprecated
  def self.parse(file, &config)
    warn "Todoer.parse is deprecated. Use Todoer.load with adapters instead"
    lines = []
    File.open(File.expand_path(file)) {|f| lines = f.readlines }
    Todo.parse lines, &config
  end
  
  class Todo
    include Enumerable
    
    #@deprecated
    def self.parse(lines, &config)
      warn "Todo.parse is deprecated. Use Adapters::Todo instead"
      new *lines.map {|line| Todoer::LogEntry.parse(line) }.compact, &config
    end
    
    # todo.mark_done = 'done'   #>> deleted tasks are instead tagged 'done'
    attr_accessor :mark_done
    
    def initialize(*new_entries)
      warn "Todo.new with block is deprecated. Use Todoer.configure instead" if block_given?
      yield self if block_given?    # really don't need this; use tap
      self.push *new_entries
    end
    
    def <<(entry)
      reset_cache; log_entries << entry
    end
      
    def push(*new_entries)
      reset_cache; log_entries.push(*new_entries)
    end
    
    
    def each(&blk)
      tasks.each(&blk)
    end
    alias each_task each
    
    def tasks
      return @tasks if @tasks
      @tasks = []
      log_entries.sort_by(&:logtime).each do |e|
        if e.add?; add_task e.task, e.logtime, e.categories; end
        if e.sub?; sub_task e.task, e.logtime, e.categories; end
      end
      @tasks
    end
    
    def tasks!
      reset_cache; self.tasks
    end
    
    def category(*cats)
      tasks.select {|t| t.categories_like?(*cats)}
    end
    alias [] category
    
    # probably should be private
    def add_task(task, timestamp, categories=[])
      (@tasks ||= []) << Task.new(task,timestamp,categories)
    end

    # probably should be private
    def sub_task(task, timestamp, categories=[])
      task = Task.new(task,timestamp,categories)
      if tag = self.mark_done then
        (@tasks ||= []).select {|t| task == t}.each do |t|
          t.tag! tag
        end
      else
        (@tasks ||= []).delete_if {|t| task == t}
      end
    end
         
    #TODO
    def compact
    end
    
    private
    
    def log_entries; @log_entries ||= []; end
    def reset_cache; @tasks = nil; end
    
    
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

  end

end
