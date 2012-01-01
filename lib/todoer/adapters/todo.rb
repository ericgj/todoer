module Todoer

  module Adapters
  
    class Todo
      include Enumerable
      
      def initialize(file, opts={})
        @mode = opts.delete(:mode) || 'r'
        @file, @opts = File.expand_path(file), opts
      end
      
      def log_entries
        return @log_entries if @log_entries
        init_storage
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
    
      private
      
      def init_storage
        unless File.exists?(@file)
          FileUtils.mkdir_p File.dirname(@file)
          File.open(@file,'w', 0644) { }
        end        
      end
      
    end
    
  end
end