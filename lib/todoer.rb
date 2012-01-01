require File.expand_path('version', File.dirname(__FILE__))
require File.expand_path('todoer/loader', File.dirname(__FILE__))
require File.expand_path('todoer/markup_string', File.dirname(__FILE__))
require File.expand_path('todoer/log_entry', File.dirname(__FILE__))
require File.expand_path('todoer/todo', File.dirname(__FILE__))
require File.expand_path('todoer/query_collection',File.dirname(__FILE__))
require File.expand_path('todoer/presenter', File.dirname(__FILE__))

module Todoer  

  def self.debug(msg)
    $stderr.puts msg if $DEBUG
  end
  
end