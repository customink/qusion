# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "qusion/version"

Gem::Specification.new do |s|
  s.name             = %q{qusion}
  s.version          = Qusion::VERSION
  s.platform         = Gem::Platform::RUBY
  s.authors          = ["Dan DeLeo", "James Tucker", "Christopher R. Murphy"]
  s.email            = %q{chmurph2+git@gmail.com}
  s.homepage         = "https://github.com/customink/qusion"
  s.summary          = %q{Makes AMQP work with Ruby on Rails with no fuss.}
  s.description      = s.summary

  s.rubyforge_project = "qusion"

  # files
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # RDoc
  s.extra_rdoc_files = ["LICENSE", "README.md"]

  #Dependencies
  s.add_dependency "amqp", ">= 0.7"
  s.add_dependency "eventmachine", ">= 0.12"
  s.add_development_dependency "cucumber", ">= 0.9.4"
  s.add_development_dependency "rspec", "~> 1.3.0"
end