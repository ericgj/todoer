require File.expand_path('test_helper',File.dirname(__FILE__))

require File.expand_path('../lib/todo',File.dirname(__FILE__))

describe 'Task #==' do

  it 'should match if categories match and name strings match' do
    @subject1 = Todo::Task.new("a task for you",['some','category'])
    @subject2 = Todo::Task.new("a task for you",['some','category'])
    assert @subject1 == @subject2
    assert @subject2 == @subject1
  end
  
  it 'should match if categories match and first name string equals start of second name string' do
    @subject1 = Todo::Task.new("a task",['some','category'])
    @subject2 = Todo::Task.new("a task for you",['some','category'])
    assert @subject1 == @subject2
  end
  
  it 'should not match if categories match and second name string is longer than second name string' do
    @subject1 = Todo::Task.new("a task",['some','category'])
    @subject2 = Todo::Task.new("a task for you",['some','category'])
    refute @subject2 == @subject1
  end
  
  it 'should not match if categories are in different order' do
    @subject1 = Todo::Task.new("a task",['some','category'])
    @subject2 = Todo::Task.new("a task",['category','some'])
    refute @subject1 == @subject2
    refute @subject2 == @subject1
  end
  
end