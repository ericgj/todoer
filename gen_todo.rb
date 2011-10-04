#! /usr/bin/env ruby
puts "# #{$0}"
require File.expand_path('lib/todoer',File.dirname(__FILE__))

todo = Todoer.parse('~/.todo') {|t| t.mark_done = 'DONE' }

todo['hacking','todoer','*'].sort_by(&:timestamp).reverse.each do |task|
  puts "- #{task} " + (task.tags.empty? ? "" : " -- #{task.tags.join(' ')}")
end