require File.expand_path('test_helper',File.dirname(__FILE__))

require File.expand_path('../lib/todoer/markup_string', File.dirname(__FILE__))
require File.expand_path('../lib/todoer/todo',File.dirname(__FILE__))

describe 'Todo#mark_done' do

  def add_and_sub
    @subject.add "task 1", Time.now, %w( a )
    @subject.add "task 2", Time.now, %w( a )
    @subject.add "task 3", Time.now, %w( a )
    @subject.sub "task 2", Time.now, %w( a )
    @subject.add "task 4", Time.now, %w( a )
    @subject.sub "task 1", Time.now, %w( a )
  end
  
  before do
    @subject = Todoer::Todo.new
  end
  
  it 'when mark_done is not set, then task is removed on sub' do
    add_and_sub
    assert_equal ["task 3", "task 4"], @subject.tasks.map(&:name)  
  end
  
  it 'when mark_done is set, then task is not removed on sub' do
    @subject.mark_done = 'booga'
    add_and_sub
    assert_equal ["task 1", "task 2", "task 3", "task 4"], @subject.tasks.map(&:name)  
  end
  
  it 'when mark_done is set, then sub tasks are tagged' do
    @subject.mark_done = 'booga'
    add_and_sub
    assert_includes @subject.tasks[0].tags, 'booga'
    assert_includes @subject.tasks[1].tags, 'booga'
  end
 
  it 'when mark_done is set, then non-sub tasks are not tagged' do
    @subject.mark_done = 'booga'
    add_and_sub
    refute_includes @subject.tasks[2].tags, 'booga'
    refute_includes @subject.tasks[3].tags, 'booga'
  end
  
end