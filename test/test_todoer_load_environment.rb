require 'tempfile'

require File.expand_path('test_helper',File.dirname(__FILE__))

require File.expand_path('../lib/todoer', File.dirname(__FILE__))
require File.expand_path('../lib/todoer/cli', File.dirname(__FILE__))


module Fixtures

  GLOBAL_TODO   = Tempfile.new(['todo','.todo']); GLOBAL_TODO.close
  
  A_TODO = Tempfile.new('A')
  A_TODO.write <<-_____
Next release:
  - Write some scripts
  - Write some tests
_____
  A_TODO.close
  
  B_TODO = Tempfile.new(['B', '.todo'])
  B_TODO.write <<-_____
+ [Wed Sep 28 03:57:27 EDT 2011] mu hackfest, reply to @diana 
+ [Wed Sep 28 03:58:36 EDT 2011] mu alumni, write alumni to set up time for social gathering on mon
+ [Wed Sep 28 04:03:38 EDT 2011] mu hackfest, draft hackfest announcement due today
- [Thu Sep 29 20:58:17 EDT 2011] mu hackfest, reply to @diana
- [Thu Sep 29 22:59:30 EDT 2011] mu hackfest, draft hackfest announcement
_____
  B_TODO.close
    
  C_TODO = Tempfile.new(['C', '.yaml'])
  C_TODO.write <<-_____
Christmas:
  - Practice carols
  - Bake cookies
  - Make presents
  - Wrap
New Years:
  - Make resolutions
  - Donations
  - Buy champagne
_____
  C_TODO.close
  
  PROJECTS_LIST_HASH = { 'A' => A_TODO.path,
                         'B' => B_TODO.path,
                         'C' => C_TODO.path
                       }
  PROJECTS_LIST = Tempfile.new(['projects','.yaml'])
  PROJECTS_LIST.write YAML.dump(PROJECTS_LIST_HASH)
  PROJECTS_LIST.close
      
end

module Dummy
  def dummy_global_todo(file=Fixtures::GLOBAL_TODO.path)
    @env.set :global_todo, file
  end
  
  def dummy_projects_list(file=Fixtures::PROJECTS_LIST.path)
    @env.set :projects_list, file
  end
end  

# Note these 'tests' are merely done by inspection of debug output for now
$DEBUG = true

describe 'Todoer.load_environment' do
  include Dummy
  
  describe 'all' do

    before do
      @env = Todoer::Environment.new(:all => true)
      dummy_global_todo
      dummy_projects_list
    end
    
    it 'should load' do
      Todoer.debug "----------#{self.__name__}(#{self.class})"
      Todoer.load_environment(@env)
      assert true
    end
  
  end
  
  describe 'global only' do
  
    before do
      @env = Todoer::Environment.new(:global => true)
      dummy_global_todo
      dummy_projects_list
    end
    
    it 'should load' do
      Todoer.debug "----------#{self.__name__}(#{self.class})"
      Todoer.load_environment(@env)
      assert true
    end
    
  end

  describe 'project only, name specified' do

    before do
      @env = Todoer::Environment.new(:project => :C)
      dummy_global_todo
      dummy_projects_list
    end
    
    it 'should load' do
      Todoer.debug "----------#{self.__name__}(#{self.class})"
      Todoer.load_environment(@env)
      assert true
    end

  end
  
  describe 'project only, path specified' do

    before do
      @env = Todoer::Environment.new(:project => Fixtures::B_TODO.path)
      dummy_global_todo
      dummy_projects_list
    end
    
    it 'should load' do
      Todoer.debug "----------#{self.__name__}(#{self.class})"
      Todoer.load_environment(@env)
      assert true
    end

  end
  
  describe 'project only, path specified, file doesnt exist' do

    before do
      @env = Todoer::Environment.new(:project => '/fake/path/to/nothing.todo')
      dummy_global_todo
      dummy_projects_list
    end
    
    it 'should raise error on loading' do
      Todoer.debug "----------#{self.__name__}(#{self.class})"
      assert_raises Errno::ENOENT do Todoer.load_environment(@env) end
    end

  end
  
  describe 'global and project' do

    before do
      @env = Todoer::Environment.new(:project => :A, :global => true)
      dummy_global_todo
      dummy_projects_list
    end
    
    it 'should load' do
      Todoer.debug "----------#{self.__name__}(#{self.class})"
      Todoer.load_environment(@env)
      assert true
    end
    
  end

  
end