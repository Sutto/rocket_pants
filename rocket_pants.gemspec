# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
Gem::Specification.new do |s|
  s.name        = "rocket_pants"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Darcy Laycock"]
  s.email       = ["sutto@thefrontiergroup.com.au"]
  s.homepage    = "http://github.com/thefrontiergroup"
  s.summary     = "JSON API love for Rails and ActionController"
  s.description = "Rocket Pants adds JSON API love to Rails and ActionController, making it simpler to built resource-oriented controllers."
  s.required_rubygems_version = ">= 1.3.6"
  
  s.add_dependency 'actionpack', '~> 3.0.3'
  s.add_dependency 'railties',   '~> 3.0.3'
  s.add_development_dependency 'rspec',       '~> 2.4.0'
  s.add_development_dependency 'rspec-rails', '~> 2.4.0'
  s.add_development_dependency 'rr',          '~> 1.0.0'
  
  s.files        = Dir.glob("{lib}/**/*")
  s.require_path = 'lib'
end