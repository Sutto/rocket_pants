require 'rubygems'
require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

task :default => :spec

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec)

namespace :spec do

  namespace :integration do

    desc "Run the will_paginate integrate specs"
    RSpec::Core::RakeTask.new(:will_paginate) do |t|
      t.rspec_opts = "--tag integration"
      t.pattern = "./spec/integration/will_paginate_spec.rb"
    end

    desc "Run the will_paginate integrate specs"
    RSpec::Core::RakeTask.new(:kaminari) do |t|
      t.rspec_opts = "--tag integration"
      t.pattern = "./spec/integration/kaminari_spec.rb"
    end

  end

  desc "Run all specs with rcov"
  RSpec::Core::RakeTask.new(:rcov) do |t|
    t.rcov = true
    t.pattern = "./spec/**/*_spec.rb"
    t.rcov_opts = '--exclude spec/,/gems/,/Library/,/usr/,lib/tasks,.bundle,config,/lib/rspec/,/lib/rspec-'
  end
end

task :default => ["spec:integration:will_paginate", "spec:integration:kaminari"]