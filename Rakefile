require 'rubygems'
require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'

task :default => :spec

begin
  require 'ci/reporter/rake/rspec'
rescue LoadError
end

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc "Run all specs with rcov"
  RSpec::Core::RakeTask.new(:rcov) do |t|
    t.rcov = true
    t.pattern = "./spec/**/*_spec.rb"
    t.rcov_opts = '--exclude spec/,/gems/,/Library/,/usr/,lib/tasks,.bundle,config,/lib/rspec/,/lib/rspec-'
  end
end