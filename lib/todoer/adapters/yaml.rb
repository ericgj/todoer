require 'yaml'

module Todoer

  module Adapters
  
    class Yaml
      include Enumerable
      
      def initialize(file, opts={})
        @categories = opts.delete(:categories) || []
        @categories = [@categories] if String === @categories || Symbol === @categories
        @categories.map! {|cat| cat.to_s}
        @parse_errors = opts.delete(:parse_errors) || :warn
        @file, @opts = file, opts
      end
      
      def log_entries
        return @log_entries if @log_entries
        parsed = catch_parse_error {
          yaml = YAML.load_file(@file)
          parse(yaml, @categories)
        }
        @log_entries =  parsed || []
      end
      
      def log_entries!
        @log_entries = nil; log_entries
      end
      
      def each(&blk)
        log_entries.each(&blk)
      end

      # Note the logtime kludge. This is because the entries are ordered by
      # logtime when converted to todo entries.
      # Possibly instead should sort by logtime + entry order?
      def parse(yaml, cats=[], iter=-1.0)
        validate yaml, cats
        t = Time.now
        yaml.inject([]) {|memo, (cat, list)|
          (Hash === list ? [list] : list).each do |item|
            case item
            when String
              iter+=0.01
              memo << Todoer::LogEntry.new_sub(:logtime => t + iter, 
                                               :categories => cats.to_a + [cat], 
                                               :task => item,
                                               :source => @file
                                              )
              iter+=0.01
              memo << Todoer::LogEntry.new_add(:logtime => t + iter, 
                                               :categories => cats.to_a + [cat], 
                                               :task => item,
                                               :source => @file
                                              )
            when Hash
              memo += parse(item, cats.to_a + [cat], iter)
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
      
      private
      
      def catch_parse_error
        yield
      rescue
        if @parse_errors.respond_to?(:call)
          @parse_errors.call $!
        else
          msg = "Error parsing todo #{@file}\n" +
                "Underlying error: #{$!}" 
          case @parse_errors
          when :error
            raise
          when :warn, :break
            warn msg
          end
        end
        nil        
      end
      
    end
  
  end
end