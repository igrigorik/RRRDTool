require 'spec'
require 'delorean'
require 'rrstat'
require 'time'

describe RRStat do
  include Delorean

  let(:rr) { RRStat.new(:precision => 10, :buckets => 6) }

  before(:each) { time_travel_to("Jan 1 2010") }
  before(:each) { rr.flushdb }

  it "should initialize db" do
    lambda {
      RRStat.new(:precision => 10, :buckets => 6)
    }.should_not raise_error
  end

  it "should return score of item" do
    rr.score("test", "random_key").should == 0
  end

  it "should increment buckets within correct epoch" do
    rr.epoch("test").should match(/test:210394200/)

    rr.incr("test", "key")
    rr.score("test", "key").should == 1

    rr.incr("test", "key", 2)
    rr.score("test", "key").should == 3

    # advance to next epoch
    time_travel_to(Time.now + 10) do
      rr.epoch("test").should match(/test:210394201/)

      rr.incr("test", "key")
      rr.score("test", "key").should == 4
    end

    # advance 5 epochs, to scroll original incr's off the list
    time_travel_to(Time.now + 40) do
      rr.epoch("test").should match(/test:210394206/)

      rr.incr("test", "key")
      rr.score("test", "key").should == 2
    end
  end

  it "should return top N items from all epochs" do
    rr.incr("test", "key1", 1)
    rr.incr("test", "key2", 3)

    # advance to next epoch
    time_travel_to(Time.now + 10) do
      rr.epoch("test").should match(/test:210394201/)
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
      rr.epoch("test").should match(/test:210394201/)
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
      rr.epoch("test").should match(/test:210394201/)
      rr.incr("test", "key")
      rr.score("test", "key").should == 2

      rr.delete("test", "key")
      rr.score("test", "key").should == 0
    end
  end
end