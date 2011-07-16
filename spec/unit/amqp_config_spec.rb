# encoding: UTF-8
require "spec_helper"
require "stub_rails"

describe AmqpConfig do

  it "should use #{Rails.root}/config/amqp.yml" do
    AmqpConfig.new.config_path.should == "/path/to/rails/config/amqp.yml"
  end

  it "should use the provided path no matter what" do
    path = AmqpConfig.new("/custom/path/to/amqp.yml").config_path
    path.should == "/custom/path/to/amqp.yml"
  end

  it "should use a provided options hash if given" do
    conf = AmqpConfig.new(:host => "my-broker.mydomain.com")
    conf.config_path.should be_nil
    conf.config_opts.should == {:host => "my-broker.mydomain.com"}
  end

  it "should use the default amqp options in rails if amqp.yml doesn't exist" do
    Rails.stub!(:root).and_return(File.dirname(__FILE__) + '/../')
    AmqpConfig.new.config_opts.should == {}
  end

  it "should load a YAML file when using a framework" do
    conf = AmqpConfig.new
    conf.stub!(:config_path).and_return(File.dirname(__FILE__) + "/../fixtures/framework-amqp.yml")
    conf.stub!(:framework_env).and_return("production")
    conf.config_opts.should == {:host => 'localhost',:port => 5672,
                                :user => 'guest', :pass => 'guest',
                                :vhost => '/', :timeout => 3600,
                                :logging => false, :ssl => false}
  end

  it "should use the first set of opts when given a explicit file path" do
    conf = AmqpConfig.new
    conf.stub!(:config_path).and_return(File.dirname(__FILE__) + "/../fixtures/hardcoded-amqp.yml")
    conf.stub!(:framework_env).and_return(nil)
    p conf.config_opts
    conf.config_opts.should == {:host => 'localhost',:port => 5672,
                                :user => 'guest', :pass => 'guest',
                                :vhost => '/', :timeout => 600,
                                :logging => false, :ssl => false}
  end

end
