require 'spec_helper'

describe RocketPants::Client do
  
  let(:test_client) do
    Class.new RocketPants::Client
  end
  
  describe 'setting versioned endpoints' do
    
    it 'should default to no version' do
      RocketPants::Client._version.should be_nil
      test_client._version.should be_nil
    end
    
    it 'should let you set the version' do
      test_client.version 1
      test_client._version.should == 1
      test_client.new.send(:endpoint).should == '1'
    end
    
    it 'should let you change the version' do
      test_client.version 1
      client = test_client.new
      test_client.version 2
      test_client._version.should == 2
      client.send(:endpoint).should == '2'
    end
    
    it 'should merge the endpoint with the version' do
      test_client.endpoint 'test'
      test_client.version 1
      client = test_client.new
      client.send(:endpoint).should == '1/test'
      test_client.version 2
      client.send(:endpoint).should == '2/test'
    end
    
  end
  
  describe 'handling errors' do
    
    let(:test_client) do
      Class.new(RocketPants::Client).tap do |c|
        c.version  1
        c.base_uri "http://localhost:3000"
      end
    end
    
    let(:client) { test_client.new }
    subject      { client }
    
    it 'should correctly raise an error when the response has an error' do
      stub_with_fixture :get, 'error?', 'simple_error'
      expect do
        client.get 'error'
      end.to raise_error
    end
    
    it 'should use error description for the exception' do
      begin
        stub_with_fixture :get, 'error?', 'simple_error'
        client.get 'error'
      rescue RocketPants::Error => e
        error_object = Crack::JSON.parse(api_fixture_json('simple_error'))
        e.message.should == error_object["error_description"]
      end
    end
    
    it 'should use error messages for invalid_resource exception' do
      begin
        stub_with_fixture :get, 'error?', 'invalid_resource_error'
        client.get 'error'
      rescue RocketPants::Error => e
        error_object = Crack::JSON.parse(api_fixture_json('invalid_resource_error'))
        e.context.should be_kind_of(Hash)
        e.errors.should  == error_object["messages"]
        e.message.should == error_object["error_description"]
      end
    end

    it 'should use the rocket pants error registry' do
      stub_with_fixture :get, 'error?', 'simple_error'
      expect do
        client.get 'error'
      end.to raise_error(RocketPants::Throttled)
    end
    
    it 'should default to a normal rocket pants error' do
      stub_with_fixture :get, 'error?', 'unknown_error'
      expect do
        client.get 'error'
      end.to raise_error(RocketPants::Error)
    end
    
  end
  
  describe 'handling responses' do
    
    let(:test_client) do
      Class.new(RocketPants::Client).tap do |c|
        c.version  1
        c.base_uri "http://localhost:3000"
      end
    end
    
    let(:client) { test_client.new }
    subject      { client }
    
    it 'should correctly unpack normal objects' do
      stub_with_fixture :get, 'test?', 'simple_object'
      client.get('test').should == {
        'name' => 'My Simple Object'
      }
    end
    
    it 'should correct unpack ordinary types' do
      stub_with_fixture :get, 'test?', 'simple_string'
      client.get('test').should == 'Hello World'
    end
    
    it 'should correctly unpack paginated objects' do
      stub_with_fixture :get, 'test?', 'paginated'
      response = client.get('test')
      response.should be_kind_of(WillPaginate::Collection)
      response.total_pages.should == 5
      response.total_entries.should == 20
      response.should == Crack::JSON.parse(api_fixture_json('paginated'))['response']
    end
    
    it 'should correctly unpack arrays of objects' do
      stub_with_fixture :get, 'test?', 'collection'
      response = client.get('test')
      response.should be_kind_of(Array)
      response.should == Crack::JSON.parse(api_fixture_json('collection'))['response']
    end
    
  end
  
  describe 'handling structured responses' do
    
    class Structured < APISmith::Smash
      property :name
    end
    
    let(:test_client) do
      Class.new(RocketPants::Client).tap do |c|
        c.version  1
        c.base_uri "http://localhost:3000"
      end
    end
    
    let(:client) { test_client.new }
    subject      { client }
    
    it 'should default to a hash' do
      stub_with_fixture :get, 'test?', 'simple_object'
      client.get('test').should be_a Hash
    end
    
    it 'should let you specify a transformer' do
      stub_with_fixture :get, 'test?', 'simple_object'
      client.get('test', :transformer => Structured).should be_a Structured
      client.get('test', :transformer => Structured).name.should == "My Simple Object"
      client.get('test', :as => Structured).should be_a Structured
      client.get('test', :as => Structured).name.should == "My Simple Object"
    end
    
    it 'should automatically handle transforming arrays' do
      stub_with_fixture :get, 'test?', 'collection'
      response = client.get('test', :transformer => Structured)
      response.should be_an Array
      response.size.should be > 0
      response.should be_all { |v| v.is_a?(Structured) }
    end
    
    it 'should automatically handle transforming paginated' do
      stub_with_fixture :get, 'test?', 'paginated'
      response = client.get('test', :transformer => Structured)
      response.should be_an WillPaginate::Collection
      response.size.should be > 0
      response.should be_all { |v| v.is_a?(Structured) }
    end
    
  end
  
  describe 'initialisation' do
    
    let(:test_client) do
      Class.new(RocketPants::Client).tap do |c|
        c.version  1
        c.base_uri "http://localhost:3000"
      end
    end
    
    let(:client) { test_client.new :api_host => 'http://localhost:3001/' }
    subject      { client }
    
    it 'should make it easy to set an api host' do
      add_response_stub stub_request(:get, 'http://localhost:3001/1/test?'), 'simple_object'
      client.get('test').should == Crack::JSON.parse(api_fixture_json('simple_object'))['response']
    end
    
  end
  
end