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
# The ~/.todo file itself is the product of a few simple bash programs, see
# other gist files for details.
#
require 'time'
require 'yaml'
require 'set'

class Todo

  def self.parse(lines, &config)
    new *lines.map {|line| LogEntry.parse(line) }.compact, &config
  end
  
  attr_reader :tasks
  attr_accessor :mark_done
  
  def initialize(*entries)
    @tasks = []
    yield self if block_given?
    entries.sort_by(&:logtime).each do |e|
      if e.add?; add e.task, e.categories; end
      if e.sub?; sub e.task, e.categories; end
      if e.change?; change e.task, e.categories; end
    end
  end
   
  def add(task, categories=[])
    @tasks << Task.new(task,categories)
  end

  def sub(task, categories=[], tag=self.mark_done)
    task = Task.new(task,categories)
    if tag then
      @tasks.select {|t| task == t}.each do |t|
        t.tag tag
      end
    else
      @tasks.delete_if {|t| task == t}
    end
  end

  def change(task, categories=[])
    sub task, categories, nil
    add task, categories
  end
   
  def aggregate(meth=nil)
    tasks.inject({}) {|memo,task|
      trav = memo
      task.categories.each do |cat| 
        trav = ( trav[cat] ||= {} )
      end
      (trav['tasks'] ||= []) << (meth ? task.send(meth) : task)
      memo
    }
  end
  
  def category(cat)
    aggregate[cat]
  end
  alias [] category
  
  def to_yaml
    YAML.dump(aggregate(:name_with_tags))
  end
  
  class Task
    attr_reader :categories, :tags
    attr_accessor :name

     def initialize(task, categories=[])
       @name, @categories = task, categories
       @tags = Set.new
     end

     def recategorize(*cats)
       @categories = cats
     end
     
     def categorize(cat)
       @categories.pop
       @categories << cat
     end
     
     def tag(t)
       @tags << t
     end
     
     def name_with_tags
       "#{self.name}" +
        (self.tags.empty? ? "" : " (#{self.tags.to_a.join('; ')})")     
     end
     
     def to_s
       "#{self.categories.join(":")}: #{self.name}" +
        (self.tags.empty? ? "" : ": (#{self.tags.to_a.join('; ')})")
     end

     def ==(other)
       (self.categories == other.categories) and
	     (/^#{self.name}/ =~ other.name)
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
    def change?; @action == '*'; end

  end

end


if $0 == __FILE__

   lines = []
   File.open(File.expand_path('~/.todo')) {|f| lines = f.readlines}

   # todo list where completed tasks are removed
   t = Todo.parse(lines)
   puts t.to_yaml
   
   # todo list where completed tasks are tagged "done"
   t2 = Todo.parse(lines) {|todo| todo.mark_done = "done"}
   puts t2.to_yaml
   
end
