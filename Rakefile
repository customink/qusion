require 'rake'
require 'rake/rdoctask'
require 'rubygems'
require 'bundler'
require "spec/rake/spectask"

desc 'Default: run specs.'
task :default => :spec

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "qusion"
    gem.summary = "Makes AMQP work with Ruby on Rails with no fuss."
    gem.description = %Q{Makes AMQP work with Ruby on Rails with no fuss.}
    gem.email = "cmurphy@customink.com"
    gem.homepage = "http://github.com/customink/qusion"
    gem.authors = ["Dan DeLeo", "Christopher R. Murphy"]
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end
Jeweler::RubygemsDotOrgTasks.new

desc "Run all of the specs"
Spec::Rake::SpecTask.new do |t|
  t.ruby_opts << '-rubygems'
  t.spec_opts = ['--options', "spec/spec.opts"]
  t.fail_on_error = false
end

namespace :spec do
  desc "Generate HTML report for failing examples"
  Spec::Rake::SpecTask.new('report') do |t|
    t.ruby_opts << '-rubygems'
    t.spec_files = FileList['failing_examples/**/*.rb']
    t.spec_opts = ["--format", "html:doc/tools/reports/failing_examples.html", "--diff", '--options', '"spec/spec.opts"']
    t.fail_on_error = false
  end

  desc "Run all spec with RCov"
  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.ruby_opts << '-rubygems'
    t.rcov = true
    t.rcov_dir = 'doc/tools/coverage/'
    t.rcov_opts = ['--exclude', 'spec']
  end
end

Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "qusion #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end