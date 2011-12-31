require 'tempfile'

require File.expand_path('test_helper',File.dirname(__FILE__))

require File.expand_path('../lib/todoer/log_entry',File.dirname(__FILE__))
require File.expand_path('../lib/todoer/adapters',File.dirname(__FILE__))
require File.expand_path('../lib/todoer/adapters/todo',File.dirname(__FILE__))

module Fixtures

  TIMES = [ 'Thu Sep 29 12:29:04 EDT 2011',
            'Thu Sep 29 12:29:52 EDT 2011',
            'Sun Oct 2 05:16:43 EDT 2011',
            'Sun Oct 2 05:17:37 EDT 2011'
          ]
          
  CATEGORIES = ['ert progreq',
                'ert ops-metrics', 
                'personal move',
                'personal move'
               ]
  
  ACTIONS = ['+','-','-','+']
  
  ADDRECS =  Tempfile.new(['addrecs','.todo']) 
  ADDRECS.write %Q{
+ [#{TIMES[0]}] #{CATEGORIES[0]}, add summary report showing production hrs per week by SA due sun
+ [#{TIMES[1]}] #{CATEGORIES[1]}, warn SAs if they enter more than 40 hrs/wk ('are you sure'?) due sun
+ [#{TIMES[2]}] #{CATEGORIES[2]}, clean refrigerator due today
+ [#{TIMES[3]}] #{CATEGORIES[3]}, wash and pack winter clothes due wed
}
  ADDRECS.close

  SUBRECS =  Tempfile.new(['subrecs','.todo']) 
  SUBRECS.write %Q{
- [#{TIMES[0]}] #{CATEGORIES[0]}, add summary report showing production hrs per week by SA due sun
- [#{TIMES[1]}] #{CATEGORIES[1]}, warn SAs if they enter more than 40 hrs/wk ('are you sure'?) due sun
- [#{TIMES[2]}] #{CATEGORIES[2]}, clean refrigerator due today
- [#{TIMES[3]}] #{CATEGORIES[3]}, wash and pack winter clothes due wed
}
  SUBRECS.close
  
  MIXRECS =  Tempfile.new(['mixrecs','.todo']) 
  MIXRECS.write %Q{
#{ACTIONS[0]} [#{TIMES[0]}] #{CATEGORIES[0]}, add summary report showing production hrs per week by SA due sun
#{ACTIONS[1]} [#{TIMES[1]}] #{CATEGORIES[1]}, warn SAs if they enter more than 40 hrs/wk ('are you sure'?) due sun
#{ACTIONS[2]} [#{TIMES[2]}] #{CATEGORIES[2]}, clean refrigerator due today
#{ACTIONS[3]} [#{TIMES[3]}] #{CATEGORIES[3]}, wash and pack winter clothes due wed
}
  MIXRECS.close
  
  
  BADRECS =   Tempfile.new(['badrecs', '.todo'])
  BADRECS.write %Q{
- [#{TIMES[0]}] #{CATEGORIES[0]}, add summary report showing production hrs per week by SA due sun
+ [#{TIMES[1]}] #{CATEGORIES[1]}, warn SAs if they enter more than 40 hrs/wk ('are you sure'?) due sun
+ [#{TIMES[2]}] This is an invalid line
- [#{TIMES[3]}] #{CATEGORIES[3]}, wash and pack winter clothes due wed
}
  BADRECS.close
  
  BADTIMERECS =   Tempfile.new(['badtimerecs', '.todo'])
  BADTIMERECS.write %Q{
- [#{TIMES[0]}] #{CATEGORIES[0]}, add summary report showing production hrs per week by SA due sun
+ [booga] #{CATEGORIES[1]}, warn SAs if they enter more than 40 hrs/wk ('are you sure'?) due sun
+ [#{TIMES[2]}] #{CATEGORIES[3]}, This is an invalid line
- [#{TIMES[3]}] #{CATEGORIES[3]}, wash and pack winter clothes due wed
}
  BADTIMERECS.close
  
end

describe 'Todo#each' do

  before do
    @subject = Todoer::Adapters::Todo
  end
  
  [Fixtures::ADDRECS, Fixtures::SUBRECS, Fixtures::MIXRECS].each do |fixture|
    it "must parse all input lines" do
      assert_equal 4, @subject.new(fixture.path).count
    end
    
    it "must create LogEntry for each input line" do
      @subject.new(fixture.path).each do |entry|
        assert_kind_of Todoer::LogEntry, entry
      end
    end
    
    it "must parse times" do
      @subject.new(fixture.path).each_with_index do |entry, i|
        assert_equal Time.parse(Fixtures::TIMES[i]), entry.logtime
      end
    end

    it "must parse categories" do
      @subject.new(fixture.path).each_with_index do |entry, i|
        assert_equal Fixtures::CATEGORIES[i].split(' '), entry.categories
      end
    end
    
  end
  
  it "must parse adds" do
    @subject.new(Fixtures::ADDRECS.path).each_with_index do |entry, i|
      assert entry.add?, "Expected entry #{i} to be add, was not"
    end
  end
  
  it "must parse subs" do
    @subject.new(Fixtures::SUBRECS.path).each_with_index do |entry, i|
      assert entry.sub?, "Expected entry #{i} to be sub, was not"
    end
  end
  
  it "must parse mixed recs" do
    @subject.new(Fixtures::MIXRECS.path).each_with_index do |entry, i|
      if Fixtures::ACTIONS[i] == '-'
        assert entry.sub?, "Expected entry #{i} to be sub, was not"
      elsif Fixtures::ACTIONS[i] == '+'
        assert entry.add?, "Expected entry #{i} to be add, was not"
      end
    end
  end
  
  it 'must raise error when invalid line' do
    assert_raises Todoer::AdapterError do
      @subject.new(Fixtures::BADRECS.path).each do |entry| entry end
    end
  end

  it 'must raise error when invalid time within line' do
    assert_raises Todoer::AdapterError do
      @subject.new(Fixtures::BADTIMERECS.path).each do |entry| entry end
    end
  end
  
end