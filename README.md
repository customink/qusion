# Qusion

Qusion makes [AMQP](https://github.com/ruby-amqp/amqp) work with your
web server with no fuss. It offers three features:

* It sets up the required callbacks and/or worker threads so that AMQP will
  work with Passenger, Thin, or Mongrel. WEBrick, SCGI, and Evented Mongrel
  are experimentally supported, but not heavily tested.       
* A Channel Pool. You can cause problems for yourself if you create new
  channels (with MQ.new) for every request. The pool sets up a few of these
  when your app starts and reuses them.  
* YAML configuration files. In Rails, create config/amqp.yml then fill in the
  details for development, test and production. Use Qusion.start() in your
  environment.rb file (or an initializer) and you're good to go.

## This fork of Qusion

This is a fork of James Tucker's [fork](https://github.com/raggi/qusion) of
Dan DeLeo's original [version](https://github.com/danielsdeleo/qusion). Tucker
did a fair amount of cleanup, mostly to the threading logic, so I went with his
fork. Improvements I've made include:    

* Conversion from a Rails plugin to this gem.
* Support for Rails 3.
* Removed support for Merb (it complicated the code and tests; just use Rails 3).

## Before You Start

Qusion makes it easy to just install and start using AMQP in your application.
But there are many ways to use background jobs within a Rails app, so it's
worth taking some time to consider the tradeoffs of each approach.

* If your background job needs are simple and you're using a relational
  database, [Delayed::Job](http://github.com/tobi/delayed_job/) lets you
  schedule background tasks through the database. You won't need to run
  another application (the AMQP Broker) to keep your app running.  
* It may make more sense to run your AMQP subscriber(s) as a
  [daemon](https://rubygems.org/gems/daemons) instead of via Qusion. This way
  it's easy to monitor/restart it if it goes down. Some prefer to publish 
  messages using [Bunny](https://github.com/ruby-amqp/bunny), a synchronous 
  gem. This is a fairly common
  [approach](http://pivotallabs.com/users/will/blog/articles/966-how-to-not-test-rabbitmq-part-1).
* Qusion runs EventMachine in a separate thread on Phusion Passenger, Mongrel,
  and other non-evented servers. There are some inefficiencies in Ruby 1.8's
  threading model that make running EM in a thread quite slow. Joe Damato and
  Aman Gupta have created a
  [patch](http://github.com/ice799/matzruby/tree/heap_stacks) for the problem
  which is included in an experimental branch of REE. You can learn more about
  the patch from Phusion's
  [Blog](http://blog.phusion.nl/2009/12/15/google-tech-talk-on-ruby-enterprise-edition/).

## Getting Started

First you'll need the amqp library and a working RabbitMQ installation. This
entails:

* Install Erlang for your platform
* Install RabbitMQ for your platform
  * On OSX, use [Homebrew](https://github.com/mxcl/homebrew) to install Erlang 
    and RabbitMQ: `brew install rabbitmq`
* Install bundler: http://gembundler.com/
* Include the qusion gem in your Rails project's Gemfile: `gem "qusion"`

Create an initializer (e.g. config/initializers/qusion.rb) and add:   

    Qusion.start

    EM.next_tick do
      # do some AMQP stuff
    end

And that's it! This will set up AMQP for any ruby app server (tested on
mongrel, thin, and passenger). Now, you can use all of AMQP's functionality as
normal. In your controllers or models, you might have:

    MQ.new.queue("my-work-queue").publish("do work, son!")

and it should just work.

## Channel Pools

It's considered bad practice to use MQ.new over and over, as it creates a new
AMQP channel, and that creates a new Erlang process in RabbitMQ. Erlang
processes are super light weight, but you'll be wasting them and causing the
Erlang VM GC headaches if you create them wantonly. So don't do that. Instead,
use the channel pool provided by Qusion. It's simple: wherever you'd normally
put MQ.new, just replace it with Qusion.channel. Examples:

    # Create a queue:
    Qusion.channel.queue("my-worker-queue")
    # Topics:
    Qusion.channel.topic("my-topic-exchange")
    # etc.   

This feature is a bit experimental, so the optimal pool size isn't known yet.
The default is 5. You can change it by adding something like the following to
your environment.rb:

    Qusion.channel_pool_size(3)

## Configuration

You can put your AMQP server details in config/amqp.yml and Qusion will load
it when you call Qusion.start(). Example:

    # Put this in config/amqp.yml
    default: &default
      host: localhost
      port: 5672
      user: guest
      pass: guest
      vhost: /
      timeout: 3600 # seconds
      logging: false
      ssl: false

    development:
      <<: *default

    test:
      <<: *default

If you're too hardcore for Rails (maybe you're using Sinatra or Ramaze), you
can still use a YAML config file, but there's no support for different
environments. So do something like this:

    # Tell Qusion where your config file is:
    Qusion.start("/path/to/amqp.yml")

    # Your configuration looks like this:
    application:
      host: localhost
      port: 5672
      ... 

If you just want to get started without configuring anything, Qusion.start()
will use the default options if it can't find a config file. And, finally, you
can give options directly to Qusion.start() like this:

    Qusion.start(:host => "my-amqp-broker.mydomain.com", :user => "me", :pass => "am_I_really_putting_this_in_VCS?")

## Bugs? Hacking?

If you find any bugs, or feel the need to add a feature, fork away. Pull
requests are very welcome. You can also report an issues via Github.

## Shouts
* Qusion's code for Phusion Passenger's starting\_worker\_process event was originally posted by Aman Gupta (tmm1[http://github.com/tmm1]) on the AMQP list[http://groups.google.com/group/ruby-amqp]
* Brightbox's Warren[http://github.com/brightbox/warren] library provides some similar functionality. It doesn't support webserver-specific EventMachine setup, but it does have built-in encryption and support for the synchronous (non-EventMachine) Bunny[http://github.com/celldee/bunny] AMQP client.

Original author: dan@kallistec.com
Forked by: chmurph2+git@gmail.com