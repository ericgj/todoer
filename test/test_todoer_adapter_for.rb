require 'tempfile'

require File.expand_path('test_helper',File.dirname(__FILE__))

require File.expand_path('../lib/todoer/loader',File.dirname(__FILE__))
require File.expand_path('../lib/todoer/todo',File.dirname(__FILE__))

module Fixtures
  
  TODOFILE = Tempfile.new(['','.todo'])
  YAMLFILE = Tempfile.new(['TODO', '.yaml'])
  NOEXTFILE = Tempfile.new('TODO')
  
end

describe 'Todoer.adapter_for' do
  
  it 'must return the specified adapter if specified' do
    actual = Todoer.adapter_for(Fixtures::TODOFILE.path, :todo)
    assert_equal Todoer::Adapters.const_get('Todo'), actual
  end
  
  [[Fixtures::YAMLFILE, 'Yaml'],
   [Fixtures::TODOFILE, 'Todo']
  ].each do |(fixture, classname)|
    it "must return the #{classname} adapter based on extension if not specified" do
      actual = Todoer.adapter_for(fixture.path)
      assert_equal Todoer::Adapters.const_get(classname), actual                   
    end
  end
  
  it 'must return the Yaml adapter if no extension and not specified' do
    actual = Todoer.adapter_for(Fixtures::NOEXTFILE.path)
    assert_equal Todoer::Adapters.const_get('Yaml'), actual                
  end
  
end
