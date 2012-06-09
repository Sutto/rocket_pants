require 'spec_helper'

describe RocketPants, 'Configuration' do

  describe 'the environment' do

    around :each do |test|
      restoring_env 'RAILS_ENV', 'RACK_ENV' do
        with_config :env, nil, &test
      end
    end

    it 'should have an environment' do
      RocketPants.env.should be_present
      RocketPants.env.should be_a ActiveSupport::StringInquirer
    end

    it 'should set it correctly' do
      RocketPants.env = "my_new_env"
      RocketPants.env.should == "my_new_env"
      RocketPants.env.should be_a ActiveSupport::StringInquirer
    end

    it 'should default to the Rails env if present' do
      ENV['RAILS_ENV'], ENV['RACK_ENV'] = "production", "staging"
      RocketPants.env.should be_production
      RocketPants.env.should_not be_staging
      RocketPants.env.should_not be_development
    end

    it 'should default to the rack env with no rails env if present' do
      ENV['RAILS_ENV'], ENV['RACK_ENV'] = nil, "staging"
      RocketPants.env.should_not be_production
      RocketPants.env.should be_staging
      RocketPants.env.should_not be_development
    end

    it 'should default to development otherwise' do
      ENV['RAILS_ENV'], ENV['RACK_ENV'] = nil, nil
      RocketPants.env.should_not be_production
      RocketPants.env.should_not be_staging
      RocketPants.env.should be_development
    end

    it 'should let you restore the environment' do
      RocketPants.env = 'other'
      RocketPants.env = nil
      RocketPants.env.should == RocketPants.default_env
    end

  end

  describe 'passing through errors' do

    around :each do |test|
      with_config :pass_through_errors, nil, &test
    end

    it 'should allow you to force it to false' do
      RocketPants.pass_through_errors = false
      RocketPants.should_not be_pass_through_errors
    end

    it 'should allow you to force it to true' do
      RocketPants.pass_through_errors = true
      RocketPants.should be_pass_through_errors
    end

    it 'should default to if the env is dev or test' do
      %w(development test).each do |environment|
        stub(RocketPants).env { ActiveSupport::StringInquirer.new environment }
        RocketPants.pass_through_errors = nil
        RocketPants.should be_pass_through_errors
      end
    end

    it 'should default to false in other envs' do
      %w(production staging).each do |environment|
        stub(RocketPants).env { ActiveSupport::StringInquirer.new environment }
        RocketPants.pass_through_errors = nil
        RocketPants.should_not be_pass_through_errors
      end
    end

  end

end