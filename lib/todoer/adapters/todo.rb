module Todoer

  module Adapters
  
    class Todo
      include Enumerable
      
      def initialize(file, opts={})
        @mode = opts.delete(:mode) || 'r'
        @file, @opts = file, opts
      end
      
      def log_entries
        return @log_entries if @log_entries
        @log_entries = []
        File.open(@file, @mode) do |f|
          f.each_line do |line| 
            next if line.chomp.strip.empty?
            if block_given?
              yield(parse(line.chomp))
            else
              @log_entries << parse(line.chomp)
            end
          end
        end
        @log_entries unless block_given?
      end
            
      def log_entries!(&blk)  
        @log_entries = nil; log_entries(&blk)
      end
      
      def each(&blk)
        log_entries(&blk)
      end
        
      def parse(line)
        if /^(\+|\-|\*)\s\[(.*)\]\s([^,]+),\s*(.*)$/ =~ line
          begin  
            Todoer::LogEntry.new $1, $2, $3, $4, @file
          rescue
            raise Todoer::AdapterError, "Error parsing todo line: #{line}\n" +
                                        "Underlying error: #{$!}"
          end
        else
          raise Todoer::AdapterError, "Unable to parse todo line: #{line}"
        end
      end
    
    end
    
  end
end