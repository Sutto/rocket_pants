require 'spec_helper'
require 'active_model_serializers'

describe RocketPants::Base, 'active_model_serializers integration', :integration => true, :target => 'active_model_serializers' do
  include ControllerHelpers

  use_reversible_tables :fish, :scope => :all

  # t.string  :name
  # t.string  :latin_name
  # t.integer :child_number
  # t.string  :token

  let(:fish)   { Fish.create! :name => "Test Fish", :latin_name => "Fishus fishii", :child_number => 1, :token => "xyz" }
  after(:each) { Fish.delete_all }

  class SerializerA < ActiveModel::Serializer
    attributes :name, :latin_name
  end

  class SerializerB < ActiveModel::Serializer
    attributes :name, :child_number
  end

  describe 'on instances' do

    it 'should let you disable the serializer' do
      with_config :serializers_enabled, false do
        mock(TestController).test_data { fish }
        dont_allow(fish).active_model_serializer
        get :test_data
        content[:response].should be_present
        content[:response].should be_a Hash
      end
    end

    it 'should use the active_model_serializer' do
      mock(TestController).test_data { fish }
      mock(fish).active_model_serializer { SerializerB }
      mock.proxy(SerializerB).new(fish, anything) { |r| r }
      get :test_data
      content[:response].should be_present
      content[:response].should be_a Hash
      content[:response].keys.map(&:to_sym).should =~ [:name, :child_number]
    end

    it 'should let you specify a custom serializer' do
      mock(TestController).test_data { fish }
      mock(TestController).test_options { {:serializer => SerializerA} }
      mock.proxy(SerializerA).new(fish, anything) { |r| r }
      get :test_data
      content[:response].should be_present
      content[:response].should be_a Hash
      content[:response].keys.map(&:to_sym).should =~ [:name, :latin_name]
    end

    it 'should use serializable_hash without a serializer' do
      dont_allow(SerializerA).new(fish, anything)
      dont_allow(SerializerB).new(fish, anything)
      mock(TestController).test_data { fish }
      expected_keys = fish.serializable_hash.keys.map(&:to_sym)
      mock.proxy(fish).serializable_hash.with_any_args { |r| r }
      get :test_data
      content[:response].should be_present
      content[:response].should be_a Hash
      content[:response].keys.map(&:to_sym).should =~ expected_keys
    end

    it 'should pass through url options' do
      mock(TestController).test_data { fish }
      mock(TestController).test_options { {:serializer => SerializerA} }
      mock.proxy(SerializerA).new(fish, rr_satisfy { |h| h[:url_options].present? }) { |r| r }
      get :test_data
      content[:response].should be_present
      content[:response].should be_a Hash
      content[:response].keys.map(&:to_sym).should =~ [:name, :latin_name]
    end

  end

  describe 'on arrays' do

    it 'should work with array serializers' do
      mock(TestController).test_data { [fish] }
      mock(fish).active_model_serializer { SerializerB }
      mock.proxy(SerializerB).new(fish, anything) { |r| r }
      get :test_data
      content[:response].should be_present
      content[:response].should be_a Array
      serialized_fish = content[:response].first
      serialized_fish.should be_a Hash
      serialized_fish.keys.map(&:to_sym).should =~ [:name, :child_number]
    end

    it 'should support each_serializer' do
      mock(TestController).test_data { [fish] }
      mock.proxy(SerializerA).new(fish, anything) { |r| r }
      mock(TestController).test_options { {:each_serializer => SerializerA} }
      get :test_data
      content[:response].should be_present
      content[:response].should be_a Array
      serialized_fish = content[:response].first
      serialized_fish.should be_a Hash
      serialized_fish.keys.map(&:to_sym).should =~ [:name, :latin_name]
    end

    it 'should default to the serializable hash version' do
      dont_allow(SerializerA).new(fish, anything)
      dont_allow(SerializerB).new(fish, anything)
      mock(TestController).test_data { [fish] }
      expected_keys = fish.serializable_hash.keys.map(&:to_sym)
      mock.proxy(fish).serializable_hash.with_any_args { |r| r }
      get :test_data
      content[:response].should be_present
      content[:response].should be_a Array
      serialized_fish = content[:response].first
      serialized_fish.should be_a Hash
      serialized_fish.keys.map(&:to_sym).should =~ expected_keys
    end

    it 'should pass through url options' do
      mock(TestController).test_data { [fish] }
      mock(TestController).test_options { {:each_serializer => SerializerA} }
      mock.proxy(SerializerA).new(fish, rr_satisfy { |h| h[:url_options].present? }) { |r| r }
      get :test_data
      content[:response].should be_present
      content[:response].should be_a Array
      serialized_fish = content[:response].first
      serialized_fish.should be_a Hash
      serialized_fish.keys.map(&:to_sym).should =~ [:name, :latin_name]
    end

    it 'should default to root being false' do
      mock(TestController).test_data { [fish] }
      mock(TestController).test_options { {:each_serializer => SerializerA} }
      mock.proxy(SerializerA).new(fish, rr_satisfy { |h| h[:root] == false }) { |r| r }
      get :test_data
      content[:response].should be_present
      content[:response].should be_a Array
      serialized_fish = content[:response].first
      serialized_fish.should be_a Hash
      serialized_fish.keys.map(&:to_sym).should =~ [:name, :latin_name]
    end

  end

end