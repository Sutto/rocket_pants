source :rubygems

# Allow testing multiple versions with Travis.
rails_version = ENV['RAILS_VERSION']
if rails_version && rails_version.length > 0
  puts "Testing Rails Version = #{rails_version}"
  # Override the specific versions
  gem 'railties',   rails_version
  gem 'actionpack', rails_version
end

group :integration do
  gem 'kaminari', :require => nil
end

gem 'ci_reporter', '~> 1.6', :require => nil

gemspec