require 'yaml'

module Todoer

  module Adapters
  
    class Yaml
      include Enumerable
      
      def initialize(file, opts={})
        @categories = opts.delete(:categories) || []
        @categories = [@categories] if String === @categories || Symbol === @categories
        @categories.map! {|cat| cat.to_s}
        @file, @opts = file, opts
      end
      
      def log_entries
        return @log_entries if @log_entries
        yaml = YAML.load_file(@file)
        @log_entries = parse(yaml, @categories)
      end
      
      def log_entries!
        @log_entries = nil; log_entries
      end
      
      def each(&blk)
        log_entries.each(&blk)
      end

      def parse(yaml, cats=[])
        validate yaml, cats
        yaml.inject([]) {|memo, (cat, list)|
          (Hash === list ? [list] : list).each do |item|
            case item
            when String
              memo << Todoer::LogEntry.new_sub(:logtime => Time.now, 
                                               :categories => cats.to_a + [cat], 
                                               :task => item,
                                               :source => @file
                                              )
              memo << Todoer::LogEntry.new_add(:logtime => Time.now + 1, 
                                               :categories => cats.to_a + [cat], 
                                               :task => item,
                                               :source => @file
                                              )
            when Hash
              memo += parse(item, cats.to_a + [cat])
            end
          end
          memo
        }
      end
      
      def validate(yaml, cats=[])
        msg = 'Invalid format YAML todo file'
        unless Hash === yaml
          raise Todoer::AdapterError, 
            [msg, 'at ' + cats.join(', '), 'expecting hash'].join(': ')
        end
        i=-1
        yaml.each do |(cat, list)|
          i+=1
          unless String === cat
            raise Todoer::AdapterError, 
              [msg, 'at ' + cats.join(', '), "key #{i} is not a category string"].join(': ')
          end
          unless Array === list || Hash === list
            raise Todoer::AdapterError,
              [msg, 'at ' + cats.join(', '), "value of key #{i} is not a list"].join(': ')
          end
        end
      end
      
    end
  
  end
end