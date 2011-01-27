require 'spec_helper'

describe RocketPants::Base do
  include ControllerHelpers
  
  def self.controller_class
    TestController
  end
  
  describe 'versioning' do
    
    it 'should ok with a valid version' do
      %w(1 2).each do |version|
        get :echo, {}, :version => version.to_s
        content[:error].should be_nil
      end
    end
    
    it 'should return an error for an invalid version number' do
      [0, 3, 10, 2.5, 2.2, '1.1'].each do |version|
        get :echo, {}, :version => version.to_s
        content[:error].should == 'invalid_version'
      end
    end
    
    it 'should return an error for no version number' do
      get :echo, {}, :version => nil
      content[:error].should == 'invalid_version'
    end
    
  end
  
  describe 'respondable' do
    
    it 'should correctly convert a will paginate collection' do
      pager = WillPaginate::Collection.create(2, 10) { |p| p.replace %w(a b c d e f g h i j); p.total_entries = 200 }
      mock(TestController).test_data { pager }
      get :test_data
      content.should have_key(:pagination)
      content[:pagination].should == {
        :next => 3,
        :current => 2,
        :previous => 1,
        :pages => 20,
        :count => 200,
        :per_page => 10,
        :count => 200
      }.stringify_keys
      content.should have_key(:count)
      content.should have_key(:pagination)
    end
    
    it 'should correctly convert a normal collection' do
      mock(TestController).test_data { %w(a b c d) }
      get :test_data
      content[:response].should == %w(a b c d)
      content[:pagination].should be_nil
      content[:count].should == 4
    end
    
    it 'should correctly convert a normal object' do
      object = {:a => 1, :b => 2}
      mock(TestController).test_data { object }
      get :test_data
      content[:count].should be_nil
      content[:pagination].should be_nil
      content[:response].should == {'a' => 1, 'b' => 2}
    end
    
    it 'should correctly convert an object with a serializable hash method' do
      object = {:a => 1, :b => 2}
      stub(object).serializable_hash(anything) { {:serialised => true}}
      mock(TestController).test_data { object }
      get :test_data
      content[:response].should == {'serialised' => true}
    end
    
    it 'should correct convert an object with as_json' do
      object = {:a => 1, :b => 2}
      stub(object).as_json(anything) { {:serialised => true}}
      mock(TestController).test_data { object }
      get :test_data
      content[:response].should == {'serialised' => true}
    end
    
  end
  
  describe 'error handling' do
    
    it 'should throw the correct error for invalid api versions' do
      get :echo, {}, :version => '3'
      content['error'].should == 'invalid_version'
    end
    
    it 'should return the correct output for a manually thrown error' do
      get :demo_exception
      content['error'].should == 'throttled'
      content['error_description'].should be_present
    end
    
    it 'should stop the flow if you raise an exception' do
      get :premature_termination
      content['error'].should be_present
      content['error_description'].should be_present
      content['response'].should be_nil
    end
    
    it 'should use i18n for error messages' do
      with_translations :rocket_pants => {:errors => {:throttled => 'Oh noes, a puddle.'}} do
        get :demo_exception
      end
      content['error'].should == 'throttled'
      content['error_description'].should == 'Oh noes, a puddle.'
    end
    
  end
  
end