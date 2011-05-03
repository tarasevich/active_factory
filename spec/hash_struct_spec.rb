require 'active_factory/hash_struct'

describe "HashStruct" do
  before(:each) {
    @h = ActiveFactory::HashStruct.
        new :key1 => :value1, :key2 => :value2
  }
  it "should be hash" do
    @h.should be_a Hash
  end

  it "should provide access to keys" do
    @h[:key1].should == :value1
    @h[:key2].should == :value2
  end

  it "should provide getter" do
    @h.key1.should == :value1
    @h.key2.should == :value2
  end
end