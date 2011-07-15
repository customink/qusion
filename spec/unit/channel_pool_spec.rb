# encoding: UTF-8
require "spec_helper"

describe ChannelPool do
  MQ = Object.new

  before(:each) do
    ChannelPool.reset
    @channel_pool = ChannelPool.instance
  end

  it "should be singleton" do
    lambda { ChannelPool.new }.should raise_error
  end

  it "should adjust the pool size" do
    ChannelPool.pool_size = 5
    ChannelPool.pool_size.should == 5
  end

  it "should reset itself when the pool size is set" do
    ChannelPool.should_receive(:reset)
    ChannelPool.pool_size = 23
  end

  it "should create a pool of AMQP channels" do
    ChannelPool.pool_size = 3
    ::AMQP::Channel.should_receive(:new).exactly(3).times
    @channel_pool.pool
  end

  it "should default to a pool size of 5" do
    ::AMQP::Channel.should_receive(:new).exactly(5).times.and_return("swanky")
    @channel_pool.pool
    @channel_pool.instance_variable_get(:@pool).should == %w{ swanky swanky swanky swanky swanky}
  end

  it "should return a channel in a round-robin" do
    class I
      def initialize(i)
        @i = i
      end
      def open?
        true
      end
      def reset
      end
      def ==(x)
        @i == x
      end
    end
    p = [1,2,3,4,5].map { |i| I.new(i) }
    @channel_pool.instance_variable_set(:@pool,p)
    @channel_pool.channel.should == 3
    @channel_pool.channel.should == 4
    @channel_pool.channel.should == 5
    @channel_pool.channel.should == 1
    @channel_pool.channel.should == 2
    @channel_pool.channel.should == 3
  end
  
  it "should reopen a closed channel" do
    ChannelPool.pool_size = 1
    mock_channel = mock('AMQP::Channel')
    mock_channel.should_receive(:open?).exactly(1).times.and_return(false)
    ::AMQP::Channel.should_receive(:new).exactly(2).times.and_return(mock_channel)
    @channel_pool.channel
  end
  
  it "should reset a channel" do
    mock_channel = mock('AMQP::Channel')
    mock_channel.should_receive(:open?).and_return(true)
    mock_channel.should_receive(:reset).exactly(1).times
    ::AMQP::Channel.should_receive(:new).at_least(:once).and_return(mock_channel)
    @channel_pool.channel
  end

end
