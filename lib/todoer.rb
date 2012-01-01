Dir[File.expand_path('core_ext/**/*', File.dirname(__FILE__))].each do |f|
  require f
end

require File.expand_path('version', File.dirname(__FILE__))
require File.expand_path('todoer/loader', File.dirname(__FILE__))
require File.expand_path('todoer/markup_string', File.dirname(__FILE__))
require File.expand_path('todoer/log_entry', File.dirname(__FILE__))
require File.expand_path('todoer/todo', File.dirname(__FILE__))
require File.expand_path('todoer/query_collection',File.dirname(__FILE__))
require File.expand_path('todoer/presenter', File.dirname(__FILE__))

module Todoer  

  def self.debug(*msgs)
    $stderr.puts *msgs if $DEBUG
  end
  
end