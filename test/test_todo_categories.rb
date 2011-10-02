require File.expand_path('test_helper',File.dirname(__FILE__))

require File.expand_path('../lib/todoer/markup_string', File.dirname(__FILE__))
require File.expand_path('../lib/todoer/todo',File.dirname(__FILE__))

describe 'Todo#categories' do
  
  before do
    @subject = Todoer::Todo.new
    @subject.add "task 1", Time.now, ["a"]
    @subject.add "task 2", Time.now, ["b"]
    @subject.add "task 3", Time.now, ["a"]
    @subject.add "task 4", Time.now, ["a", "b"]
    @subject.add "task 5", Time.now, ["a", "b", "c"]
    @subject.add "task 6", Time.now, ["a", "c", "b"]
  end
  
  it 'should return all the tasks exactly matching single passed category' do
    assert_equal ["task 1", "task 3"], @subject["a"].map(&:name)
  end

  it 'should return all the tasks exactly matching 2 passed categories' do
    assert_equal ["task 4"], @subject["a", "b"].map(&:name)
  end
  
  it 'should return all the tasks exactly matching 3 passed categories' do
    assert_equal ["task 5"], @subject["a", "b", "c"].map(&:name)
  end
  
end