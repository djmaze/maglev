
class IdentityHash
  # a dictionary similar to a Hash but using identity comparision,
  #   i.e.  equal?()  ,  to compare keys.

  # Class methods
  class_primitive_nobridge '__new', 'new'

  def self.new
    # args are ignored
    __new
  end

  def self.from_hash(a_hash)
    ih = self.__new 
    a_hash.each { | k,v |
      ih[k] = v
    }
    ih
  end

  def ==(other)
    if (other.class._equal?(self.class))
      if (other._equal?(self))
        return true
      end
      unless other.length._equal?(self.length)
        return false
      end
      each { |k,v|
         unless other[k] == v
           return false
         end
      }
      true
    else
      false
    end
  end

  primitive 'hash' , '_hash'

  primitive_nobridge '__at_otherwise', 'at:otherwise:'
  def [](key)
    # returns the value for key, or nil if key not found
    __at_otherwise(key, nil)
  end

  primitive_nobridge '[]=', 'at:put:'

  primitive 'clear', 'removeAllKeys'

  primitive 'delete', 'removeKey:'

  primitive 'each&', 'keysAndValuesDo:'
  primitive 'each_key&', 'keysDo:'
  primitive 'each_pair&', 'keysAndValuesDo:'
  primitive 'each_value&', 'valuesDo:'

  def empty?
    size._equal?(0)
  end

  primitive 'has_key?', 'includesKey:'

  def has_value?(val)
    each do |k,v|
      return true if val == v
    end
    false
  end

  primitive 'index', 'keyAtValue:'
  primitive 'keys', 'keys'
  primitive 'key?', 'includesKey:'
  primitive 'length', 'size'

  primitive 'rehash', 'rebuildTable:'

  primitive 'size', 'size'
  primitive  'store', 'at:put:'

  alias value? has_value?

  def values
    result = []
    each { |k,v| result << v }
    result
  end

  def values_at(*args)
    # RUBINIUS
    # TODO There is a maglev bug in Array#collect in dealing with nil
    # values from the block, so this impl exhibits the underlying bug.
    args.collect { |key| self[key] }
  end

  # Overrides from Object

  primitive   '__basic_dup', 'rubyDup'       # use non-singleton class
  primitive   '__basic_clone', 'rubyClone'   # use singleton class

  def inspect
    return "{}" if length._equal?(0)
    str = "{"
    ts = Thread.__recursion_guard_set
    added = ts.__add_if_absent(self)
    unless added
      str << '...}'
      return str
    end
    begin
      ts.add(self)
      each { |k,v|
          s = str
          s << k.inspect
          s << "=>"
          s << v.inspect
          s << ", "
         }
      str[0..(str.length - 3)] + "}"
    ensure
      ts.remove(self)
    end
    str
  end

end
