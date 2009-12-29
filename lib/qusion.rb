# encoding: UTF-8
require "eventmachine"
require "mq"

require "qusion/server_spy"
require "qusion/channel_pool"
require "qusion/amqp_config"

module Qusion
  def self.start(*opts)
    amqp_opts = AmqpConfig.new(*opts).config_opts
    start_amqp_dispatcher(amqp_opts)
  end
  
  def self.start_amqp_dispatcher(amqp_settings={})
    AMQP.settings.merge!(amqp_settings)
    case Qusion::ServerSpy.server_type
    when :passenger
      PhusionPassenger.on_event(:starting_worker_process) do |forked| 
        if forked
          EM.stop if EM.reactor_running?
          Thread.current[:mq] = nil
          AMQP.instance_variable_set(:@conn, nil)
        end
        @thread = Thread.new { start }
        die_gracefully_on_signal
      end
    when :standard
      @thread = Thread.new { start }
      die_gracefully_on_signal
    when :evented
      die_gracefully_on_signal
    when :none
    else
      raise ArgumentError, "AMQP#start_web_dispatcher requires an argument of [:standard|:evented|:passenger|:none]"
    end
    if @thread
      @thread.abort_on_exception = true
      Thread.pass until EM.reactor_running?
    end
  end

  def self.die_gracefully_on_signal
    Signal.trap("INT")  { EM.schedule { AMQP.stop { EM.stop } } }
    Signal.trap("TERM") { EM.schedule { AMQP.stop { EM.stop } } }
  end

  def self.channel
    ChannelPool.instance.channel
  end
  
  def self.channel_pool_size(new_pool_size)
    ChannelPool.pool_size = new_pool_size
  end
end
