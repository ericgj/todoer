require 'set'

# Note this is fairly naive, it assumes conditions are built up like
# ( p1 OR q2 ) AND (p2 OR q2) AND ...
# And allows you to negate any single OR condition (but not AND conditions)
#
class QueryCollection
  include Enumerable
  
  def initialize(source)
    @_source = source
  end
    
  def where(value=true, &cond)
    _select_procs << []
    self.or(value, &cond)
  end
  
  def or(value=true, &cond)
    _select_procs.last << Condition.new(cond, value && value != :not)
    self
  end
 
  def and(value=true, &cond)
    where(value, &cond)
  end
  
  def all
    to_a
  end
  
  def each
    set = _select_procs.inject(Set.new(@_source)) { |conjunction, predicates|
      items = predicates.inject(Set.new) {|disjunction, p|
        disjunction |=  if p.value
                          @_source.select(&p.to_proc)
                        else
                          @_source.reject(&p.to_proc)
                        end
        disjunction
      }
      conjunction &= items
      conjunction
    }
    set.each do |it| yield it end
  end
  
  private
  
  def _select_procs
    @_select_procs ||= []
  end
  
  class Condition
  
    attr_reader :value
    
    def initialize(predicate, value=true)
      @predicate = predicate
      @value = value
    end
    
    def negate!
      @value = !@value
      self
    end
    
    def to_proc
      @predicate
    end
    
  end
  
end

if $0 == __FILE__

  x = %w(a b c d e f g)
  
  c = QueryCollection.new(x)
  
  c.where {|it| it == 'c'}.or {|it| it == 'd'}.or(:not) {|it| it == 'g'}.and {|it| %w(b c d).include?(it)}.each do |it|
    puts it
  end
  
  
end