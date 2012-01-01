require 'tempfile'
require 'yaml'

require File.expand_path('test_helper',File.dirname(__FILE__))

require File.expand_path('../lib/todoer', File.dirname(__FILE__))
require File.expand_path('../lib/todoer/cli', File.dirname(__FILE__))

module Fixtures

  PROJECTS_LIST_HASH = { 'A' => '/path/to/A',
                         'B' => '/path/to/B.todo',
                         'C' => '/path/to/C/todo.yaml'
                       }

  GLOBAL_TODO   = Tempfile.new(['todo','.todo']); GLOBAL_TODO.close
  
  PROJECTS_LIST = Tempfile.new(['projects','.yaml'])
  PROJECTS_LIST.write YAML.dump(PROJECTS_LIST_HASH)
  PROJECTS_LIST.close
  
end

module Dummy
  def dummy_global_todo(file=Fixtures::GLOBAL_TODO.path)
    @subject.set :global_todo, file
  end
  
  def dummy_projects_list(file=Fixtures::PROJECTS_LIST.path)
    @subject.set :projects_list, file
  end
end  

describe 'Environment#sources' do
  include Dummy
  
  describe 'all' do
  
    before do
      @subject = Todoer::Environment.new(:all => true)
      dummy_global_todo
      dummy_projects_list
    end
    
    it 'should source global todo' do
      assert_equal Fixtures::GLOBAL_TODO.path, @subject.sources[:global]
    end
    
    it 'should source each project todo' do
      Fixtures::PROJECTS_LIST_HASH.each do |(k,v)|
        assert_equal v, @subject.sources[k.to_sym]
      end
    end
    
  end
  
  describe 'global only' do
    before do
      @subject = Todoer::Environment.new(:global => true)
      dummy_global_todo
      dummy_projects_list
    end
    
    it 'should source global todo' do
      assert_equal Fixtures::GLOBAL_TODO.path, @subject.sources[:global]
    end
    
    it 'should not source any other' do
      assert_equal 1, @subject.sources.count
    end
    
  end
  
  describe 'project only, name specified' do
    before do
      @subject = Todoer::Environment.new(:project => :C)
      dummy_global_todo
      dummy_projects_list
    end
    
    it 'should not source global todo' do
      refute_includes @subject.sources, :global
    end
    
    it 'should source project' do
      assert_equal Fixtures::PROJECTS_LIST_HASH['C'], @subject.sources[:C]
    end
    
    it 'should not source any other' do
      assert_equal 1, @subject.sources.count
    end
  end
  
  describe 'project only, path specified' do
    before do
      @subject = Todoer::Environment.new(:project => '/path/to/D')
      dummy_global_todo
      dummy_projects_list
    end
    
    it 'should not source global todo' do
      refute_includes @subject.sources, :global
    end
    
    it 'should source project' do
      assert_equal '/path/to/D', @subject.sources[:'/path/to/D']
    end
    
    it 'should not source any other' do
      assert_equal 1, @subject.sources.count
    end
  end
  
  describe 'global and project' do
    before do
      @subject = Todoer::Environment.new(:project => :B, :global => true)
      dummy_global_todo
      dummy_projects_list
    end
    
    it 'should source global todo' do
      assert_equal Fixtures::GLOBAL_TODO.path, @subject.sources[:global]
    end
    
    it 'should source project' do
      assert_equal Fixtures::PROJECTS_LIST_HASH['B'], @subject.sources[:B]
    end
    
    it 'should not source any other' do
      assert_equal 2, @subject.sources.count
    end
  end
  
end

describe 'Environment#save_sources!' do
  include Dummy
  
  before do
      @subject = Todoer::Environment.new(:project => :B, :global => true)
      dummy_global_todo
      dummy_projects_list 
      @subject.add_source 'D', '/path/to/D'
      @subject.add_source '/path/to/E'
      @subject.save_sources!
      @subject = Todoer::Environment.new(:all => true)
  end
  
  it 'should source newly added sources after saving' do
    assert_equal '/path/to/D', @subject.sources[:D]
    assert_equal '/path/to/E', @subject.sources[:'/path/to/E']
  end
  
  it 'should source global todo after saving' do
    assert_equal Fixtures::GLOBAL_TODO.path, @subject.sources[:global]
  end
  
  it 'should source each old project todo after saving' do
    Fixtures::PROJECTS_LIST_HASH.each do |(k,v)|
      assert_equal v, @subject.sources[k.to_sym]
    end
  end
  
end