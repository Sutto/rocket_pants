require 'spec_helper'

describe RocketPants::Error do

  def temporary_constant(items)
    items.each_pair do |k, v|
      Object.const_set k, v
    end
    yield if block_given?
  ensure
    items.each_key do |name|
      Object.send :remove_const, name
    end
  end

  let!(:unchanged_error) do
    Class.new(RocketPants::Error)
  end

  let!(:attacked_by_ninjas) do
    Class.new(RocketPants::Error) do
      http_status 422
    end
  end

  let!(:another_error) do
    Class.new(attacked_by_ninjas) do
      http_status 404
      error_name :oh_look_a_panda
    end
  end

  around :each do |test|
    temporary_constant :AnotherError => another_error, :UnchangedError => unchanged_error, :AttackedByNinjas => attacked_by_ninjas do
      test.call
    end
  end
  
  it 'should be an exception' do
    RocketPants::Error.should be < StandardError
  end
  
  describe 'working with the http status codes' do
    
    it 'should default to 400 for the status code' do
      RocketPants::Error.http_status.should == 400
      unchanged_error.http_status.should == 400
    end
    
    it 'should let you get the status code for a given class' do
      attacked_by_ninjas.http_status.should == 422
      another_error.http_status.should == 404
    end
    
    it 'should let you set the status code for a given class' do
      attacked_by_ninjas.http_status.should == 422
      another_error.http_status 403
      another_error.http_status.should == 403
      attacked_by_ninjas.http_status.should == 422
    end
    
    it 'should let you get the status code from an instance' do
      instance = another_error.new
      instance.http_status.should == another_error.http_status
    end
    
  end
  
  describe 'working with the error name' do
    
    it 'should have a sane default value' do
      unchanged_error.error_name.should == :unchanged
      RocketPants::Error.error_name.should == :unknown
      attacked_by_ninjas.error_name.should == :attacked_by_ninjas
    end
    
    it 'should let you get the error name for a given class' do
      another_error.error_name.should == :oh_look_a_panda
    end
    
    it 'should let you set the error name for a given class' do
      another_error.error_name :oh_look_a_pingu
      another_error.error_name.should == :oh_look_a_pingu
    end
    
    it 'should let you get it on an instance' do
      instance = attacked_by_ninjas.new
      instance.error_name.should == attacked_by_ninjas.error_name
    end
    
  end
  
  describe 'dealing with the error context' do
    
    it 'should let you set / get arbitrary context' do
      exception = RocketPants::Error.new
      exception.context = 'Something'
      exception.context.should == 'Something'
      exception.context = {:a => 'hash'}
      exception.context.should == {:a => 'hash'}
    end
    
    it 'should default the context to a hash' do
      RocketPants::Error.new.context.should == {}
    end
    
  end

  describe RocketPants::InvalidResource do

    let(:error_messages) { {:name => %w(a b c), :other => %w(e)} }

    it 'should let you pass in error messages' do
      o = Object.new
      mock(o).to_hash { error_messages }
      error = RocketPants::InvalidResource.new(o)
      error.context.should == {:metadata => {:messages => error_messages}}
    end

    it 'should not override messages' do
      error = RocketPants::InvalidResource.new(error_messages)
      error.context = {:other => true, :metadata => {:test => true}}
      error.context.should == {:metadata => {:messages => error_messages, :test => true}, :other => true}
    end

  end
  
end