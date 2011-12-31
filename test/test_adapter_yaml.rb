require 'tempfile'
require 'yaml'

require File.expand_path('test_helper',File.dirname(__FILE__))

require File.expand_path('../lib/todoer/log_entry',File.dirname(__FILE__))
require File.expand_path('../lib/todoer/adapters',File.dirname(__FILE__))
require File.expand_path('../lib/todoer/adapters/yaml',File.dirname(__FILE__))

module Fixtures

  SIMPLE_ARRAYS = Tempfile.new('simplearrays')
  SIMPLE_ARRAYS.write <<-_____
Personal:
  - Get milk
  - Buy stamps
  - Mail letter
  - Write email
Work:
  - do report
  - build widgets
_____
  SIMPLE_ARRAYS.close

  ARRAYS_OF_HASHES = Tempfile.new('hasharrays')
  ARRAYS_OF_HASHES.write <<-_____
Personal:
  - Family:
    - get milk
    - write email
  - Finance:
    - mail check
    - buy stamps
Work:
  - Project XYZ:
    - do report
  - Project ABC:
    - build widgets
_____
  ARRAYS_OF_HASHES.close

  MIXED_ARRAYS = Tempfile.new('mixedarrays')
  MIXED_ARRAYS.write <<-_____
Personal:
  - Get milk
  - Buy stamps
  - Mail letter
  - Write email
  - Vacation:
    - order flights
Work:
  - Do backups
  - Project XYZ:
    - do report
  - Project ABC:
    - build widgets
_____
  MIXED_ARRAYS.close

  HASH_OF_HASHES = Tempfile.new('hashhashes')
  HASH_OF_HASHES.write <<-_____
Personal:
  Family:
    - get milk
    - write email
  Finance:
    - mail check
    - buy stamps
Work:
  Project XYZ:
    - do report
  Project ABC:
    - build widgets
_____
  HASH_OF_HASHES.close
  
  HASH_OF_STRINGS = Tempfile.new('hashstrings')
  HASH_OF_STRINGS.write <<-_____
Personal: get milk
Work: do report
_____
  HASH_OF_STRINGS.close
  
  VALIDATE_SIMPLE_ARRAYS = YAML.load_file(SIMPLE_ARRAYS.path)
  VALIDATE_ARRAYS_OF_HASHES = YAML.load_file(ARRAYS_OF_HASHES.path)
  VALIDATE_MIXED_ARRAYS = YAML.load_file(MIXED_ARRAYS.path)
  VALIDATE_HASH_OF_STRINGS = YAML.load_file(HASH_OF_STRINGS.path)
  VALIDATE_HASH_OF_HASHES = YAML.load_file(HASH_OF_HASHES.path)
  
end

describe 'YAML#validate' do

  before do
    @subject = Todoer::Adapters::Yaml.new('file')
  end
  
  it 'should validate simple hash of arrays of strings' do
    @subject.validate(Fixtures::VALIDATE_SIMPLE_ARRAYS)
    assert true
  end
  
  it 'should validate hash of arrays of hashes' do
    @subject.validate(Fixtures::VALIDATE_ARRAYS_OF_HASHES)
    assert true
  end
  
  it 'should validate hash of mixed arrays of strings and hashes' do
    @subject.validate(Fixtures::VALIDATE_MIXED_ARRAYS)
    assert true
  end
  
  it 'should validate hash of hashes' do
    @subject.validate(Fixtures::VALIDATE_HASH_OF_HASHES) 
    assert true
  end
  
  it 'should invalidate hash of strings' do
    assert_raises Todoer::AdapterError do 
      @subject.validate(Fixtures::VALIDATE_HASH_OF_STRINGS) 
    end
  end
  
end

describe 'Yaml#parse' do

  before do
    @subject = Todoer::Adapters::Yaml.new('file')
  end
  
  def assert_entry_categories_at(cats, actual, i)
    actual.slice(i*2,2).each_with_index do |entry, j|
      assert_equal cats, entry.categories, 
        "Nonequal categories at entry #{i*2 + j}"
    end
  end
  
  [[Fixtures::SIMPLE_ARRAYS, 'simple hash of arrays'],
   [Fixtures::ARRAYS_OF_HASHES, 'hash of arrays of hashes'],
   [Fixtures::MIXED_ARRAYS, 'mixed arrays of strings and hashes'],
   [Fixtures::HASH_OF_HASHES, 'hash of hashes']
  ].each do |(fixture, label)|
    it "should parse #{label}" do
      input = YAML.load_file(fixture.path)
      @subject.parse(input)
      assert true
    end
    
    it "should create sub + add entries #{label}" do
      input = YAML.load_file(fixture.path)
      actual = @subject.parse(input)
      actual.each_slice(2) do |entries|
        assert entries[0].sub?, "Expected first entry to be sub:\n#{entries[0]}"
        assert entries[1].add?, "Expected second entry to be add:\n#{entries[1]}"
      end
    end
    
  end
  
  # Note all the below tests are coupled to fixtures above
  
  [[ [                    ], 'no categories passed'],
   [ ['Cat1','Cat2','Cat3'], 'categories passed'   ]
  ].each do |(passed_cats, label)|
  
    it "should parse categories in simple hash of arrays, #{label}" do
      input = YAML.load_file(Fixtures::SIMPLE_ARRAYS.path)
      actual = @subject.parse(input, passed_cats)
      #$stderr.puts actual
      (0..3).each do |i|
        assert_entry_categories_at passed_cats + ['Personal'], actual, i
      end
      (4..5).each do |i|
        assert_entry_categories_at passed_cats + ['Work'], actual, i
      end
    end

    it "should parse categories in hash of arrays of hashes, #{label}" do
      input = YAML.load_file(Fixtures::ARRAYS_OF_HASHES.path)
      actual = @subject.parse(input, passed_cats)
      #$stderr.puts actual
      (0..1).each do |i|
        assert_entry_categories_at passed_cats +  ['Personal', 'Family'], actual, i
      end
      (2..3).each do |i|
        assert_entry_categories_at passed_cats + ['Personal', 'Finance'], actual, i
      end
      assert_entry_categories_at passed_cats +  ['Work', 'Project XYZ'], actual, 4
      assert_entry_categories_at passed_cats + ['Work', 'Project ABC'], actual, 5
    end
    
    it "should parse categories in mixed arrays, #{label}" do
      input = YAML.load_file(Fixtures::MIXED_ARRAYS.path)
      actual = @subject.parse(input, passed_cats)
      #$stderr.puts actual
      (0..3).each do |i|
        assert_entry_categories_at passed_cats + ['Personal'], actual, i
      end
      assert_entry_categories_at passed_cats + ['Personal', 'Vacation'], actual, 4
      assert_entry_categories_at passed_cats + ['Work'], actual, 5
      assert_entry_categories_at passed_cats + ['Work', 'Project XYZ'], actual, 6
      assert_entry_categories_at passed_cats + ['Work', 'Project ABC'], actual, 7
    end
    
    # Note this will only pass with ordered hashes, i.e. ruby 1.9
    it "should parse categories in hash of hashes, #{label}" do
      input = YAML.load_file(Fixtures::HASH_OF_HASHES.path)
      actual = @subject.parse(input, passed_cats)
      #$stderr.puts actual
      (0..1).each do |i|
        assert_entry_categories_at passed_cats + ['Personal', 'Family'], actual, i
      end
      (2..3).each do |i|
        assert_entry_categories_at passed_cats + ['Personal', 'Finance'], actual, i
      end
      assert_entry_categories_at passed_cats + ['Work', 'Project XYZ'], actual, 4
      assert_entry_categories_at passed_cats + ['Work', 'Project ABC'], actual, 5
    end
    
  end
  
end


describe 'Yaml#each' do

  before do
    @subject = Todoer::Adapters::Yaml.new(Fixtures::HASH_OF_HASHES.path)
  end
  
  it "should yield 12 entries" do
    $stderr.puts @subject.entries
    assert_equal 12, @subject.count
    @subject.each {|e| assert_kind_of Todoer::LogEntry, e}
  end
  
end


[[ 'top',                      'single category'    ],
 [['first','second', 'third'], 'multiple categories']
].each do |(cats, label)|
  describe "Yaml.new with #{label}" do
    
    before do
      @subject = Todoer::Adapters::Yaml.new(
        Fixtures::HASH_OF_HASHES.path, :categories => cats 
      )
    end
    
    it "should yield 12 entries" do
      $stderr.puts @subject.entries
      assert_equal 12, @subject.count
      @subject.each {|e| assert_kind_of Todoer::LogEntry, e}
    end
    
    it "each entry should have prefixed #{label}" do
      $stderr.puts @subject.entries
      expected_cats = (Enumerable === cats ? cats : [cats])
      @subject.each do |e| 
        assert_equal expected_cats, e.categories[0,expected_cats.count]
      end
    end
    
  end
end