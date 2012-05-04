source :rubygems

# Allow testing multiple versions with Travis.
rails_version = ENV['RAILS_VERSION']
if rails_version && rails_version.length > 0
  puts "Testing Rails Version = #{rails_version}"
  # Override the specific versions
  gem 'railties',     rails_version
  gem 'actionpack',   rails_version
  gem 'activerecord', rails_version
end

gem 'ci_reporter', '~> 1.6', :require => nil

# 2.10 for the moment changes some exceptions.
gem 'rspec', '~> 2.9.0'

gemspec