require 'spec_helper'

describe RocketPants::Error do
  
  UnchangedError = Class.new(RocketPants::Error)
  AttackedByNinjas = Class.new(RocketPants::Error) do
    http_status 422
  end
  AnotherError = Class.new(AttackedByNinjas) do
    http_status 404
    error_name :oh_look_a_panda
  end
  
  it 'should be an exception' do
    RocketPants::Error.should be < StandardError
  end
  
  describe 'working with the http status codes' do
    
    it 'should default to 400 for the status code' do
      RocketPants::Error.http_status.should == 400
      UnchangedError.http_status.should == 400
    end
    
    it 'should let you get the status code for a given class' do
      AttackedByNinjas.http_status.should == 422
      AnotherError.http_status.should == 404
    end
    
    it 'should let you set the status code for a given class' do
      AttackedByNinjas.http_status.should == 422
      AnotherError.http_status 403
      AnotherError.http_status.should == 403
      AttackedByNinjas.http_status.should == 422
    end
    
    it 'should let you get the status code from an instance' do
      instance = AnotherError.new
      instance.http_status.should == AnotherError.http_status
    end
    
  end
  
  describe 'working with the error name' do
    
    it 'should have a sane default value' do
      UnchangedError.error_name.should == :unchanged
      RocketPants::Error.error_name.should == :unknown
      AttackedByNinjas.error_name.should == :attacked_by_ninjas
    end
    
    it 'should let you get the error name for a given class' do
      AnotherError.error_name.should == :oh_look_a_panda
    end
    
    it 'should let you set the error name for a given class' do
      AnotherError.error_name :oh_look_a_pingu
      AnotherError.error_name.should == :oh_look_a_pingu
    end
    
    it 'should let you get it on an instance' do
      instance = AttackedByNinjas.new
      instance.error_name.should == AttackedByNinjas.error_name
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
  
end