# encoding: UTF-8
require "eventmachine"
require "amqp"

require "qusion/channel_pool"
require "qusion/amqp_config"

module Qusion
  class << self
    attr_reader :thread
  end

  def self.start(*opts)
    amqp_opts = AmqpConfig.new(*opts).config_opts
    start_amqp_dispatcher(amqp_opts)
  end

  def self.start_amqp_dispatcher(amqp_settings={})
    AMQP.settings.merge!(amqp_settings)

    if defined?(::PhusionPassenger) && ::PhusionPassenger.respond_to?(:on_event)
      ::PhusionPassenger.on_event(:starting_worker_process) do |forked| 
        if forked
          EM.stop if EM.reactor_running?
          thread && thread.join
          Thread.current[:mq] = nil
          AMQP.instance_variable_set(:@conn, nil)
        end
        start_in_background
        die_gracefully_on_signal
      end
      return
    end

    start_in_background
    die_gracefully_on_signal
  end

  def self.die_gracefully_on_signal
    Signal.trap("INT")  { graceful_stop }
    Signal.trap("TERM") { graceful_stop }
  end

  def self.channel
    ChannelPool.instance.channel
  end

  def self.channel_pool_size(new_pool_size)
    ChannelPool.pool_size = new_pool_size
  end

  def self.start_in_background
    if EM.reactor_running?
      raise ArgumentError, 'AMQP already connected' if ready_to_dispatch?
      AMQP.start
    else
      raise ArgumentError, 'Qusion already started' if thread && thread.alive?
      @thread = Thread.new do
        EM.run { AMQP.start }
        raise "Premature AMQP shutdown" unless @graceful_stop
      end
      thread.abort_on_exception = true
      thread.join(0.1) until ready_to_dispatch?
    end
  end

  def self.graceful_stop
    EM.schedule do
      @graceful_stop = true
      AMQP.stop { EM.stop }
    end
    thread && thread.join
  end

  def self.ready_to_dispatch?
    EM.reactor_running? && AMQP.connection && AMQP.connection.connected?
  end
end
