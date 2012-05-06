require 'spec_helper'

describe RocketPants::ErrorHandling do
  include ControllerHelpers

  let!(:controller_class) { Class.new(TestController) }

  it 'should allow you to override the error handler' do
    get :test_error
    content.should have_key "error"
    content.should have_key "error_description"
    content[:error].should == "system"
  end

  it 'should allow you to set the error handle from a named type' do
    controller_class.exception_notifier_callback.should == controller_class::DEFAULT_NOTIFIER_CALLBACK
    controller_class.use_named_exception_notifier :airbrake
    controller_class.exception_notifier_callback.should_not == controller_class::DEFAULT_NOTIFIER_CALLBACK
    controller_class.exception_notifier_callback.should == controller_class::NAMED_NOTIFIER_CALLBACKS[:airbrake]
    controller_class.use_named_exception_notifier :nonexistant
    controller_class.exception_notifier_callback.should == controller_class::DEFAULT_NOTIFIER_CALLBACK
  end

  it 'should include the error identifier in the response if set' do
    controller_class.exception_notifier_callback = lambda do |controller, exception, req|
      controller.error_identifier = 'my-test-identifier'
    end
    get :test_error
    content[:error_identifier].should == 'my-test-identifier'
  end

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

  describe 'hooking into the built in error handling' do

    let(:controller_class) do
      klass = Class.new(TestController)
      klass.class_eval do
        rescue_from StandardError, :with => :render_error
      end
      klass
    end

    let(:error) do
      TestController::ErrorOfDoom.new("Hello there")
    end

    let!(:error_mapping) { Hash.new }

    before :each do
      # Replace it with a new error mapping.
      stub(controller_class).error_mapping { error_mapping }
      stub.instance_of(controller_class).error_mapping { error_mapping }
      stub(controller_class).test_error { error }
    end

    it 'should let you hook into the error name lookup' do
      mock.instance_of(controller_class).lookup_error_name(error).returns(:my_test_error).times(any_times)
      get :test_error
      content['error'].should == 'my_test_error'
    end

    it 'should let you hook into the error message lookup' do
      mock.instance_of(controller_class).lookup_error_message(error).returns 'Oh look, pie.'
      get :test_error
      content['error_description'].should == 'Oh look, pie.'
    end

    it 'should let you hook into the error status lookup' do
      mock.instance_of(controller_class).lookup_error_status(error).returns 403
      get :test_error
      response.status.should == 403
    end

    it 'should let you add error items to the response' do
      mock.instance_of(controller_class).lookup_error_extras(error).returns(:hello => 'There')
      get :test_error
      content['hello'].should == 'There'
    end

    it 'should let you register an item in the error mapping' do
      controller_class.error_mapping[TestController::ErrorOfDoom] = RocketPants::Throttled
      get :test_error
      content['error'].should == 'throttled'
    end

    it 'should include parents when checking the mapping' do
      stub(controller_class).test_error { TestController::YetAnotherError }
      controller_class.error_mapping[TestController::ErrorOfDoom] = RocketPants::Throttled
      get :test_error
      content['error'].should == 'throttled'
    end

  end

end