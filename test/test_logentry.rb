require File.expand_path('test_helper',File.dirname(__FILE__))

require File.expand_path('../lib/todoer/todo',File.dirname(__FILE__))

describe 'LogEntry parse' do
  
  def subject_parsed
    [:action, :logtime, :task, :categories].each do |attr|
      refute_nil @subject.send(attr)
    end
  end
  
  it 'should parse + entry' do
    @subject = Todoer::Todo::LogEntry.parse("+ [Tue Sep 20 12:13:00 EDT 2011] some categories, a task")
    assert subject_parsed
    assert @subject.add?
    assert 2, @subject.categories.length
  end
  
  it 'should parse - entry' do
    @subject = Todoer::Todo::LogEntry.parse("- [Tue Sep 20 12:13:00 EDT 2011] some more categories, a task")
    assert subject_parsed
    assert @subject.sub?
    assert 3, @subject.categories.length
  end
    
  it 'should parse entry with no space after comma' do
    @subject = Todoer::Todo::LogEntry.parse("+ [Tue Sep 20 12:13:00 EDT 2011] some categories,a task")
    assert subject_parsed
  end
  
  it 'should not parse entry with no categories' do
    @subject = Todoer::Todo::LogEntry.parse("+ [Tue Sep 20 12:13:00 EDT 2011] a task")
    assert_nil @subject
  end
  
end


__END__

  it 'should parse * entry' do
    @subject = Todoer::Todo::LogEntry.parse("* [Tue Sep 20 12:13:00 EDT 2011] cat, a task")
    assert subject_parsed
    assert @subject.change?
    assert 1, @subject.categories.length  
  end
