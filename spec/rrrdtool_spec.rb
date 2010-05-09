require 'spec'
require 'delorean'
require 'time'

require 'lib/rrrdtool'

describe RRRDTool do
  include Delorean

  let(:rr) { RRRDTool.new(:step => 10, :buckets => 6) }

  before(:each) { time_travel_to("Jan 1 2010") }
  before(:each) { rr.clear("test") }

  it "should initialize db" do
    lambda {
      RRRDTool.new(:step => 10, :buckets => 6)
    }.should_not raise_error
  end

  it "should return score of item" do
    rr.score("test", "random_key").should == 0
  end

  it "should increment buckets within correct epoch" do
    rr.epoch("test").should match(/test:0/)

    rr.incr("test", "key")
    rr.score("test", "key").should == 1

    rr.incr("test", "key", 2)
    rr.score("test", "key").should == 3

    # advance to next epoch
    time_travel_to(Time.now + 10) do
      rr.epoch("test").should match(/test:1/)

      rr.incr("test", "key")
      rr.score("test", "key").should == 4
    end

    # advance 5 epochs, to scroll original incr's off the list
    time_travel_to(Time.now + 60) do
      rr.epoch("test").should match(/test:0/)

      rr.incr("test", "key")
      rr.score("test", "key").should == 2
    end
  end

  it "should return top N items from all epochs" do
    rr.incr("test", "key1", 1)
    rr.incr("test", "key2", 3)

    # advance to next epoch
    time_travel_to(Time.now + 10) do
      rr.epoch("test").should match(/test:1/)
      rr.incr("test", "key3", 5)

      rr.first("test", 3).should == ["key3", "key2", "key1"]
      rr.first("test", 3, :with_scores => true).should == {"key3"=>"5", "key2"=>"3", "key1"=>"1"}
    end
  end

  it "should return last N items from all epochs" do
    rr.incr("test", "key1", 1)
    rr.incr("test", "key2", 3)

    # advance to next epoch
    time_travel_to(Time.now + 10) do
      rr.epoch("test").should match(/test:1/)
      rr.incr("test", "key3", 5)

      rr.last("test", 3).should == ["key1", "key2", "key3"]
      rr.last("test", 3, :with_scores => true).should == {"key1"=>"1", "key2"=>"3", "key3"=>"5"}
    end
  end

  it "should erase key from all epochs" do
    rr.incr("test", "key", 1)
    rr.score("test", "key").should == 1

    # advance to next epoch
    time_travel_to(Time.now + 10) do
      rr.epoch("test").should match(/test:1/)
      rr.incr("test", "key")
      rr.score("test", "key").should == 2

      rr.delete("test", "key")
      rr.score("test", "key").should == 0
    end
  end

  it "should footprint stats" do
    rr.incr("test", "key")
    rr.incr("test", "key2")

    time_travel_to(Time.now + 10) do
      rr.incr("test", "key")

      rr.stats("test").should == {
        :buckets => 6,
        :unique_keys => 2,
        :key_count => { 0 => 2, 1 => 1, 2 => 0, 3 => 0, 4 => 0, 5 => 0 }
      }
    end

    time_travel_to(Time.now + 60) do
      rr.stats("test").should == {
        :buckets => 6,
        :unique_keys => 1,
        :key_count => { 0 => 0, 1 => 1, 2 => 0, 3 => 0, 4 => 0, 5 => 0 }
      }
    end
  end

  it "should store & verify epoch signatures for each bucket" do
    pending "otherwise, if we skip several buckets, they won't get cleared"
  end
end