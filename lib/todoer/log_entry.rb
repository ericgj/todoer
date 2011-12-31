require 'time'
require 'date'

module Todoer

  class LogEntry
    attr_reader :action, :logtime, :task, :categories, :source

    # note: better to use alternate constructors below
    # since the default is so unfriendly
    class << self
    
      #@deprecated
      def parse(line, source=nil)
        warn "LogEntry.parse is deprecated, use Todoer::Adapters::Todo"
        return unless /^(\+|\-|\*)\s\[(.*)\]\s([^,]+),\s*(.*)$/ =~ line
        new $1, $2, $3, $4, source
      end
      
      def new_add(params = {})
        new '+', 
            params.fetch(:logtime, Time.now),
            params.fetch(:categories, []),
            params.fetch(:task, ''),
            params.fetch(:source, nil)
      end
      alias + new_add
      
      def new_sub(params = {})
        new '-', 
            params.fetch(:logtime, Time.now),
            params.fetch(:categories, []),
            params.fetch(:task, ''),
            params.fetch(:source, nil)
      end
      alias - new_sub
      
    end
    
    # TODO better input verification
    def initialize(action,logtime,categories,task,source=nil)
      @action = action
      @logtime = (String === logtime ? parse_time(logtime) : logtime)
      @categories = (String === categories ? categories.split(' ') : categories)
      @task = task
    end
    
    def add?; @action == '+'; end
    def sub?; @action == '-'; end

    def to_s
      "#{action} [#{logtime}] #{categories.join(' ')}, #{task}" 
    end
    
    private
    
    # hack, needed to raise error in 1.8.7 if bad format time
    def parse_time(t)
      if RUBY_VERSION < '1.9'
        Date.parse(t)
      end
      Time.parse(t)
    end
        
  end

end