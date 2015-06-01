require 'spec_helper'

describe RocketPants::ErrorHandling do
  include ControllerHelpers

  let!(:controller_class) { Class.new(TestController) }

  context 'error handler functions' do

    context 'when pass_through_errors is false' do
      around :each do |test|
        with_config :pass_through_errors, false, &test
      end

      it 'should allow you to set the error handle from a named type' do
        controller_class.exception_notifier_callback.should == controller_class::DEFAULT_NOTIFIER_CALLBACK

        controller_class.use_named_exception_notifier :airbrake
        controller_class.exception_notifier_callback.should_not == controller_class::DEFAULT_NOTIFIER_CALLBACK
        controller_class.exception_notifier_callback.should == controller_class::NAMED_NOTIFIER_CALLBACKS[:airbrake]

        controller_class.use_named_exception_notifier :honeybadger
        controller_class.exception_notifier_callback.should_not == controller_class::DEFAULT_NOTIFIER_CALLBACK
        controller_class.exception_notifier_callback.should == controller_class::NAMED_NOTIFIER_CALLBACKS[:honeybadger]

        controller_class.use_named_exception_notifier :bugsnag
        controller_class.exception_notifier_callback.should_not == controller_class::DEFAULT_NOTIFIER_CALLBACK
        controller_class.exception_notifier_callback.should == controller_class::NAMED_NOTIFIER_CALLBACKS[:bugsnag]

        controller_class.use_named_exception_notifier :nonexistent
        controller_class.exception_notifier_callback.should == controller_class::DEFAULT_NOTIFIER_CALLBACK
      end

      context 'named exception notifier' do
        let(:controller) { controller_class.new }

        let(:exception) { StandardError.new }

        let(:request) { Rack::Request.new({})}

        context 'airbrake' do
          let(:request_data) { { method: 'POST', path: '/' } }

          before :each do
            controller_class.use_named_exception_notifier :airbrake
            stub.instance_of(controller_class).airbrake_local_request? { false }
            stub.instance_of(controller_class).airbrake_request_data { request_data }

            Airbrake = Class.new do
              define_singleton_method(:notify) { |exception, request_data| }
            end
          end

          it 'should send notification when it is the named exception notifier' do
            mock(Airbrake).notify(exception, request_data)

            controller_class.exception_notifier_callback.call(controller, exception, request)
          end
        end

        context 'honeybadger' do
          before :each do
            controller_class.use_named_exception_notifier :honeybadger
            stub.instance_of(controller_class).notify_honeybadger {}
          end

          it 'should send notification when it is the named exception notifier' do
            mock(controller).notify_honeybadger(exception)

            controller_class.exception_notifier_callback.call(controller, exception, request)
          end
        end

        context 'bugsnag' do
          before :each do
            controller_class.use_named_exception_notifier :bugsnag
            stub.instance_of(controller_class).notify_bugsnag {}
          end

          it 'should send notification when it is the named exception notifier' do
            mock(controller).notify_bugsnag(exception, request: request)

            controller_class.exception_notifier_callback.call(controller, exception, request)
          end
        end
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
    end

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

    it 'should default to extracting metadata from the context' do
      def error.context;  {:metadata => {:hello => 'There'}} ; end
      get :test_error
      content['hello'].should == 'There'
    end

    it 'should let you pass through data via the context in the controller' do
      controller_class.send(:define_method, :demo_exception) { error! :throttled, :metadata => {:hello => "There"}}
      get :demo_exception
      content['hello'].should == 'There'
    end

    it 'should let you register an item in the error mapping' do
      controller_class.error_mapping[TestController::ErrorOfDoom] = RocketPants::Throttled
      get :test_error
      content['error'].should == 'throttled'
    end

    it 'should let you register a custom error mapping' do
      controller_class.error_mapping[TestController::ErrorOfDoom] = lambda do |exception|
        RocketPants::Throttled.new(exception)
      end
      get :test_error
      content['error'].should == 'throttled'
    end

    it 'should let you register a custom error mapping with metadata' do
      controller_class.error_mapping[TestController::ErrorOfDoom] = lambda do |exception|
        RocketPants::Throttled.new(exception).tap do |e|
          e.context = {:metadata => {:test => true}}
        end
      end
      get :test_error
      content['error'].should == 'throttled'
      content['test'].should == true
    end

    it 'should include parents when checking the mapping' do
      stub(controller_class).test_error { TestController::YetAnotherError }
      controller_class.error_mapping[TestController::ErrorOfDoom] = RocketPants::Throttled
      get :test_error
      content['error'].should == 'throttled'
    end

  end

  describe 'the default exception handler' do

    let!(:error_mapping) { Hash.new }

    before :each do
      # Replace it with a new error mapping.
      stub(controller_class).error_mapping { error_mapping }
      stub.instance_of(controller_class).error_mapping { error_mapping }
      controller_class.use_named_exception_notifier :default
    end

    it 'should pass through the exception if pass through is enabled' do
      with_config :pass_through_errors, true do
        expect { get :test_error }.to raise_error NotImplementedError
      end
    end

    it 'should catch through the exception if pass through is disabled' do
      with_config :pass_through_errors, false do
        get :test_error
        content.should have_key "error"
        content.should have_key "error_description"
        content[:error].should == "system"
      end
    end

    it 'should default to having the exception message' do
      with_config :show_exception_message, true do
        with_config :pass_through_errors, false do
          stub(controller_class).test_error { StandardError.new("This is a fake message.") }
          get :test_error
          content[:error_description].should be_present
          content[:error_description].should == "This is a fake message."
        end
      end
    end

    it 'should let you disable using the exception message' do
      with_config :show_exception_message, false do
        with_config :pass_through_errors, false do
          stub(controller_class).test_error { StandardError.new("This is a fake message.") }
          get :test_error
          content[:error_description].should be_present
          content[:error_description].should_not == "This is a fake message."
        end
      end
    end

  end

  describe 'custom exception_notifier_callback' do
    before do
      @called_exception_notifier_callback = false
    end

    let(:custom_exception_notifier_callback) {
      lambda {|c,e,r| @called_exception_notifier_callback = true }
    }

    before :each do
      # Replace it with a new error mapping.
      stub(controller_class).error_mapping { error_mapping }
      stub.instance_of(controller_class).error_mapping { error_mapping }
      controller_class.exception_notifier_callback = custom_exception_notifier_callback
    end

    it "should call the custom exception notifier callback" do
      with_config :pass_through_errors, false do
        get :test_error
        @called_exception_notifier_callback.should be_truthy
      end
    end

  end

end
