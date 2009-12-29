# encoding: UTF-8
require "eventmachine"
require "mq"

require "qusion/channel_pool"
require "qusion/amqp_config"

module Qusion
  VALID_SERVER_TYPES = [:passenger, :standard, :evented, :none]
  
  class << self
    attr_reader :thread
    attr_writer :server_type
  end

  def self.start(*opts)
    amqp_opts = AmqpConfig.new(*opts).config_opts
    start_amqp_dispatcher(amqp_opts)
  end

  def self.start_amqp_dispatcher(amqp_settings={})
    AMQP.settings.merge!(amqp_settings)

    if server_type == :passenger || defined?(::PhusionPassenger)
      ::PhusionPassenger.on_event(:starting_worker_process) do |forked| 
        next unless forked
        EM.stop if EM.reactor_running?
        Thread.current[:mq] = nil
        AMQP.instance_variable_set(:@conn, nil)
      end
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
      raise ArgumentError, 'Qusion already started' if @thread && @thread.alive?
      @thread = Thread.new { AMQP.start }
      thread.abort_on_exception = true
      thread.join(0.01) until ready_to_dispatch?
    end
  end

  def self.graceful_stop
    EM.schedule do
      AMQP.stop do
        EM.stop
      end
    end
    thread.join
  end

  def self.server_type
    @server_type ||= begin
      case
      when defined?(::PhusionPassenger)
        :passenger
      when defined?(::Mongrel::MongrelProtocol)
        :evented
      when defined?(::Thin)
        :evented
      else
        :standard
      end
    end
  end

  def self.ready_to_dispatch?
    EM.reactor_running? && AMQP.conn.connected?
  end
end