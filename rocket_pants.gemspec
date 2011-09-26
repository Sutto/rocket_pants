# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
Gem::Specification.new do |s|
  s.name        = "rocket_pants"
  s.version     = "0.1.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Darcy Laycock"]
  s.email       = ["sutto@sutto.net"]
  s.homepage    = "http://github.com/filtersquad"
  s.summary     = "JSON API love for Rails and ActionController"
  s.description = "Rocket Pants adds JSON API love to Rails and ActionController, making it simpler to build resource-oriented controllers."
  s.required_rubygems_version = ">= 1.3.6"
  
  s.add_dependency 'actionpack', '~> 3.0'
  s.add_dependency 'railties',   '~> 3.0'
  s.add_dependency 'will_paginate', '~> 3.0'
  s.add_dependency 'hashie',        '~> 1.0'
  s.add_dependency 'api_smith'
  s.add_dependency 'will_paginate'
  s.add_dependency 'moneta'
  s.add_development_dependency 'rspec',       '~> 2.4.0'
  s.add_development_dependency 'rspec-rails', '~> 2.4.0'
  s.add_development_dependency 'rr',          '~> 1.0.0'
  s.add_development_dependency 'webmock'
  
  s.files        = Dir.glob("{lib}/**/*")
  s.require_path = 'lib'
end