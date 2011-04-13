class HashStruct < Hash
  def initialize hash
    merge! hash
      keys.each { |key|
        eval %{ def self.#{key}; self[:#{key}] end }
      }
  end

  def self.[] hash
    new Hash[hash]
  end

  def merge *args
    HashStruct.new(super(*args))
  end
end