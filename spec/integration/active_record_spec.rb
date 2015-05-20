require 'spec_helper'

require 'active_record'
require 'rocket_pants/active_record'

describe RocketPants::Base, 'active record integration', :integration => true, :target => 'active_record' do
  include ControllerHelpers

  use_reversible_tables :fish, :scope => :all

  let(:controller_class) do
    Class.new(TestController)
  end

  it 'should automatically map ActiveRecord::RecordNotFound' do
    action_is { Fish.find(1000) }
    get :test_data
    content['error'].should == 'not_found'
  end

  it 'should automatically map ActiveRecord::RecordNotSaved' do
    action_is { raise ActiveRecord::RecordNotSaved.new "Hello World Exception" }
    @action_body = lambda { Fish.new.save }
    get :test_data
    content['error'].should == 'invalid_resource'
    content['messages'].should == nil
  end

  it 'should automatically map ActiveRecord::RecordInvalid' do
    action_is { Fish.new.save! }
    get :test_data
    content['error'].should == 'invalid_resource'
    messages = content['messages']
    messages.should be_present
    messages.keys.should =~ %w(name child_number latin_name)
    messages.each_pair do |name, value|
      value.should be_present
      value.should be_a Array
      value.should be_all { |v| v.is_a?(String) }
      expected = (name == 'name' ? 1 : 2)
      value.length.should == expected
    end
  end

  it 'should automatically map ActiveRecord::RecordNotUnique' do
    Fish.connection.add_index :fish, :latin_name, unique: true
    attrs = {:token => "a", :name => "Test Fish", :latin_name => "Latin Name", :child_number => 5}
    Fish.create! attrs
    action_is { Fish.create!(attrs); raise "This should not happen..." }
    get :test_data
    content['error'].should == 'conflict'
  end

end
