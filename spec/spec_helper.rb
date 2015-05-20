require 'pathname'

ENV["RAILS_ENV"] ||= 'test'
$LOAD_PATH.unshift Pathname(__FILE__).dirname.dirname.join("lib").to_s

require 'bundler/setup'
Bundler.setup
Bundler.require :default, :test

require 'rocket_pants'
require 'webmock/rspec'

# This should be a per-app configuration setting.
ActiveSupport.on_load(:active_record) do
  self.include_root_in_json = false
end

Dir[Pathname(__FILE__).dirname.join("support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rr
  config.include I18nSpecHelper
  config.include ConfigHelper
  config.include WebmockResponses
  config.extend  ReversibleData::RSpec2Macros
  config.filter_run_excluding :integration => true

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end if config.respond_to?(:expect_with)
end