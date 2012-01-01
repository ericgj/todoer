require File.expand_path('../lib/lib_trollop', File.dirname(__FILE__))

require File.expand_path('../lib/todoer', File.dirname(__FILE__))
require File.expand_path('../lib/todoer/cli', File.dirname(__FILE__))

opts = Trollop.options do 
  opt :global,  'Include global todo', :default => false
  opt :project, 'Include project todo (path or project name)', 
      :default => File.join(Dir.pwd,'.todo')
  opt :all,     'Include global and all project todos', 
      :default => false
end

Todoer::CLI.command(ARGV.shift, opts).call

