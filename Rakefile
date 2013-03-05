require 'rubygems'
require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec)

INTEGRATION_LIBS = %w(will_paginate kaminari active_record active_model_serializers rspec)

namespace :spec do

  namespace :integration do

    INTEGRATION_LIBS.each do |lib|

      desc "Run the #{lib} integrate specs"
      RSpec::Core::RakeTask.new(lib.to_sym) do |t|
        t.rspec_opts = "--tag integration"
        t.pattern = "./spec/integration/#{lib}_spec.rb"
      end

    end

  end

  desc "Run all specs with rcov"
  RSpec::Core::RakeTask.new(:rcov) do |t|
    t.rcov = true
    t.pattern = "./spec/**/*_spec.rb"
    t.rcov_opts = '--exclude spec/,/gems/,/Library/,/usr/,lib/tasks,.bundle,config,/lib/rspec/,/lib/rspec-'
  end
end

task :default => ([:spec] + INTEGRATION_LIBS.map { |l| "spec:integration:#{l}" })
