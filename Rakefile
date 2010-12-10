require 'rake'
require 'rake/rdoctask'
require 'rubygems'
require 'bundler'
require "spec/rake/spectask"
require "cucumber"
require "cucumber/rake/task"

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
    gem.description = %Q{See the README for more details.}
    gem.email = "cmurphy@customink.com"
    gem.homepage = "http://github.com/customink/qusion"
    gem.authors = ["Dan DeLeo", "Christopher R. Murphy"]
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

desc "Run Cucumber Features"
Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = "-c -n"
end

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

# I haven't published this gem to rubygems yet.  Instead, use these rake tasks
# to version and release to git only (for Bundler to pick up the new version).
# Credit: http://www.cowboycoded.com/2010/07/23/working-with-private-rubygems-in-rails-3/
namespace :version do
  desc "Run and commit gemspec"
  task :gemspec_and_commit => :gemspec do
    sh "git add *.gemspec VERSION"
    sh "git commit -m 'Updated gemspec for bundler'"
  end

  desc "Bump the patch version by 1, update gemspec, then tag and push to git."
  task :patch_release do
    Rake::Task['version:bump:patch'].invoke
    Rake::Task['version:gemspec_and_commit'].invoke
    Rake::Task['git:release'].invoke
  end

  desc "Bump the minor version by 1, update gemspec, then tag and push to git."
  task :minor_release do
    Rake::Task['version:bump:minor'].invoke
    Rake::Task['version:gemspec_and_commit'].invoke
    Rake::Task['git:release'].invoke
  end

  desc "Bump the major version by 1, update gemspec, then tag and push to git."
  task :major_release do
    Rake::Task['version:bump:major'].invoke
    Rake::Task['version:gemspec_and_commit'].invoke
    Rake::Task['git:release'].invoke
  end
end