source :rubygems

# Allow testing multiple versions with Travis.
rails_version = ENV['RAILS_VERSION']
if rails_version && rails_version.length > 0
  puts "Testing Rails Version = #{rails_version}"
  gem 'rails', rails_version
end

gem 'ci_reporter', '~> 1.6', :require => nil

gemspec