# encoding: UTF-8
require File.dirname(__FILE__) + "/../spec_helper"

describe "Qusion Convenience Methods" do
  
  it "should get a channel from the pool" do
    channel_pool = mock("channel pool")
    ChannelPool.should_receive(:instance).and_return(channel_pool)
    channel_pool.should_receive(:channel)
    Qusion.channel
  end
  
  it "should set the channel pool size" do
    ChannelPool.should_receive(:pool_size=).with(7)
    Qusion.channel_pool_size(7)
  end
  
  it "should load the configuration and setup AMQP for the webserver" do
    config = mock("config")
    AmqpConfig.should_receive(:new).and_return(config)
    config.should_receive(:config_opts).and_return(:config => :opts)
    Qusion.should_receive(:start_amqp_dispatcher).with(:config => :opts)
    Qusion.start
  end
  
end

describe Qusion, 'amqp startup' do
  
  before do
    AMQP.stub!(:settings).and_return({})
  end
  
  after(:each) do
    Object.send(:remove_const, :PhusionPassenger) if defined? ::PhusionPassenger
    Object.send(:remove_const, :Thin) if defined? ::Thin
    Object.send(:remove_const, :Mongrel) if defined? ::Mongrel
  end
  
  it "should kill the reactor and start a new AMQP connection when forked in Passenger" do
    Qusion.should_receive(:die_gracefully_on_signal).once
    ::PhusionPassenger = Module.new
    forked = mock("starting_worker_process_callback_obj")
    ::PhusionPassenger.should_receive(:on_event).with(:starting_worker_process).and_yield(forked)
    EM.should_receive(:reactor_running?).exactly(3).times.and_return(true)
    amqp_conn = mock('amqp_conn')
    amqp_conn.should_receive(:connected?).and_return(false)
    AMQP.should_receive(:conn).any_number_of_times.and_return(amqp_conn)
    EM.should_receive(:stop)
    AMQP.should_receive(:start).once
    Qusion.start_amqp_dispatcher
  end
  
  it "should set AMQP's connection settings when running under Thin" do
    Qusion.should_receive(:die_gracefully_on_signal)
    Qusion.should_receive(:start_in_background)
    ::Thin = Module.new
    Qusion.start_amqp_dispatcher(:cookie => "yummy")
    AMQP.settings[:cookie].should == "yummy"
  end
  
  it "should start a worker thread when running under Mongrel" do
    Qusion.should_receive(:die_gracefully_on_signal)
    mock_thread = mock('thread')
    mock_thread.should_receive(:abort_on_exception=).with(true)
    Qusion.should_receive(:ready_to_dispatch?).twice.and_return(false, true)
    mock_thread.should_receive(:join)
    Thread.should_receive(:new).and_return(mock_thread)
    ::Mongrel = Module.new
    Qusion.start_amqp_dispatcher
  end
  
  it "should be ready to dispatch when the reactor is running and amqp is connected" do
    EM.should_receive(:reactor_running?).and_return(true)
    amqp_conn = mock('amqp_conn')
    amqp_conn.should_receive(:connected?).and_return(true)
    AMQP.should_receive(:conn).any_number_of_times.and_return(amqp_conn)
    Qusion.ready_to_dispatch?.should == true
  end
  
end