module Todoer

  module Adapters
  
    class Todo
      include Enumerable
      
      def initialize(file, opts={})
        @mode = opts.delete(:mode) || 'r'
        @parse_errors = opts.delete(:parse_errors) || :warn
        @file, @opts = File.expand_path(file), opts
        @skip_rest = false
      end
      
      def log_entries
        return @log_entries if @log_entries
        init_storage
        @log_entries = []
        File.open(@file, @mode) do |f|
          f.each_line do |line| 
            next if line.chomp.strip.empty?
            if parsed = parse(line.chomp)
              if block_given?
                yield(parsed)
              else
                @log_entries << parsed
              end
            end
            break if @skip_rest
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
        catch_parse_error(line) {
          if /^(\+|\-|\*)\s\[(.*)\]\s([^,]+),\s*(.*)$/ =~ line
            Todoer::LogEntry.new $1, $2, $3, $4, @file
          else
            raise Todoer::AdapterError, "Unable to parse todo line: #{line}"
          end
        }
      end
    
      private
        
      def catch_parse_error(line, &blk)
        yield
      rescue
        if @parse_errors.respond_to?(:call)
          @parse_errors.call $!, line
        else
          msg = "Error parsing todo line from #{@file}\n  #{line}\n" +
                "Underlying error: #{$!}" 
          case @parse_errors
          when :error
            raise Todoer::AdapterError, msg    
          when :warn
            warn msg
          when :break
            warn msg
            warn "Note: skipping rest of file"
            @skip_rest = true
          end
        end
        nil
      end
      
      def init_storage
        unless File.exists?(@file)
          FileUtils.mkdir_p File.dirname(@file)
          File.open(@file,'w', 0644) { }
        end        
      end
      
    end
    
  end
end