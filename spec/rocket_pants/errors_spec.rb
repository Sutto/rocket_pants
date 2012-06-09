require 'spec_helper'

describe RocketPants::Errors do
  
  describe 'getting all errors' do
    
    it 'should return a list of all errors' do
      list = RocketPants::Errors.all
      list.should be_present
      list.keys.should   be_all { |v| v.is_a?(Symbol) }
      list.values.should be_all { |v| v < RocketPants::Error }
    end
    
    it 'should return a muteable list' do
      list = RocketPants::Errors.all
      list.should_not have_key(:my_error)
      RocketPants::Errors.register! :my_error
      list.should_not have_key(:my_error)
      new_list = RocketPants::Errors.all
      new_list.should_not == list
      new_list.should have_key(:my_error)
    end
    
  end
  
  describe 'getting an error from a key' do
    
    it 'should let you use an error you have registered before' do
      RocketPants::Errors.all.each_pair do |key, value|
        RocketPants::Errors[key].should == value
      end
      RocketPants::Errors.register! :ninja_error
      RocketPants::Errors[:ninja_error].should == RocketPants::NinjaError
    end
    
    
    it 'should return nil for unknown errors' do
      RocketPants::Errors[:life_the_universe_and_everything].should be_nil
    end
    
  end
  
  describe 'adding a new error' do
    
    it 'should add it to the mapping' do
      RocketPants::Errors[:fourty_two].should be_nil
      error = Class.new(RocketPants::Error)
      error.error_name :fourty_two
      RocketPants::Errors.add error
      RocketPants::Errors[:fourty_two].should == error
    end
    
  end
  
  describe 'registering an error' do
    
    it 'should add a constant' do
      RocketPants.should_not be_const_defined(:AnotherException)
      RocketPants::Errors.register! :another_exception
      RocketPants.should be_const_defined(:AnotherException)
      RocketPants::AnotherException.should be < RocketPants::Error
    end

    it 'should let you set the parent object' do
      RocketPants::Errors.register! :test_base_exception
      RocketPants::Errors.register! :test_child_exception, :base => RocketPants::TestBaseException
      RocketPants.should be_const_defined(:TestBaseException)
      RocketPants.should be_const_defined(:TestChildException)
      RocketPants::TestChildException.should be < RocketPants::TestBaseException
    end

    it 'should let you set the parent object' do
      expect do
        RocketPants::Errors.register! :test_child_exception_bad_base, :base => StandardError
      end.to raise_error ArgumentError
      RocketPants.should be_const_defined(:TestBaseException)
      RocketPants.should_not be_const_defined(:TestChildExceptionBadBase)
    end
    
    it 'should let you set the http status' do
      RocketPants::Errors.register! :another_exception_two, :http_status => :forbidden
      RocketPants::Errors[:another_exception_two].http_status.should == :forbidden
    end
    
    it 'should let you set the error name' do
      RocketPants::Errors[:threes_a_charm].should be_blank
      RocketPants::Errors.register! :another_exception_three, :error_name => :threes_a_charm
      RocketPants::Errors[:threes_a_charm].should be_present
    end
    
    it 'should let you set the class name' do
      RocketPants.should_not be_const_defined(:NumberFour)
      RocketPants::Errors.register! :another_exception_four, :class_name => 'NumberFour'
      RocketPants.should be_const_defined(:NumberFour)
      RocketPants::Errors[:another_exception_four].should == RocketPants::NumberFour
    end
    
    it 'should let you register an error under a scope' do
      my_scope = Class.new
      my_scope.should_not be_const_defined(:AnotherExceptionFive)
      RocketPants.should_not be_const_defined(:AnotherExceptionFive)
      RocketPants::Errors.register! :another_exception_five, :under => my_scope
      RocketPants.should_not be_const_defined(:AnotherExceptionFive)
      my_scope.should be_const_defined(:AnotherExceptionFive)
      RocketPants::Errors[:another_exception_five].should == my_scope::AnotherExceptionFive
    end

  end
  
end