require 'spec_helper'
require 'logger'
require 'stringio'

require 'will_paginate/collection'
# Replace stderr because kaminari complains about not having a framework.
begin
  stderr, $stderr = $stderr, StringIO.new
  require 'kaminari'
ensure
  $stderr = stderr
end

describe RocketPants::Base do
  include ControllerHelpers

  describe 'integration' do

    it 'should have the authorization helper methods' do
      instance = controller_class.new
      instance.should respond_to :authenticate_or_request_with_http_basic
      instance.should respond_to :authenticate_or_request_with_http_digest
      instance.should respond_to :authenticate_or_request_with_http_token
    end

    context 'with a model' do

      let(:table_manager) { ReversibleData.manager_for(:users) }

      before(:each) { table_manager.up! }
      after(:each)  { table_manager.down! }

      it 'should let you expose a single item' do
        user = User.create :age => 21
        mock(TestController).test_data { user }
        get :test_data
        content[:response].should == user.serializable_hash
      end

      it 'should let you expose a collection' do
        1.upto(5) do |offset|
          User.create :age => (18 + offset)
        end
        mock(TestController).test_data { User.all }
        get :test_data
        content[:response].should == User.all.map(&:serializable_hash)
        content[:count].should == 5
      end

      it 'should let you expose a kaminari-paginated collection' do
        1.upto(5) do |offset|
          User.create :age => (18 + offset)
        end
        mock(TestController).test_data { User.page(1).per(2) }
        get :test_data
        content[:response].should be_present
        content[:count].should == 2
        content[:pagination].should be_present
        content[:pagination][:count].should == 5
      end

    end

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

    pending 'should return unprocessible entity for invalid formats' do
      get :test_data, :format => :xml
      response.status.should == 422
    end

    it 'should correctly convert a kaminari array' do
      pager = Kaminari::PaginatableArray.new((1..200).to_a, :limit => 10, :offset => 10)
      mock(TestController).test_data { pager }
      get :test_data
      content.should have_key(:pagination)
      content[:pagination].should == {
        :next => 3,
        :current => 2,
        :previous => 1,
        :pages => 20,
        :count => 200,
        :per_page => 10
      }.stringify_keys
      content.should have_key(:count)
      content[:count].should == 10
    end

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
        :per_page => 10
      }.stringify_keys
      content.should have_key(:count)
      content[:count].should == 10
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

    it 'should correctly hook into paginated responses' do
      pager = WillPaginate::Collection.create(2, 10) { |p| p.replace %w(a b c d e f g h i j); p.total_entries = 200 }
      mock(TestController).test_data { pager }
      hooks = []
      mock.instance_of(TestController).pre_process_exposed_object(pager, :paginated, false) { hooks << :pre }
      mock.instance_of(TestController).post_process_exposed_object(pager, :paginated, false) { hooks << :post }
      get :test_data
      hooks.should == [:pre, :post]
    end

    it 'should correctly hook into collection responses' do
      object = %w(a b c d)
      mock(TestController).test_data { object }
      hooks = []
      mock.instance_of(TestController).pre_process_exposed_object(object, :collection, false) { hooks << :pre }
      mock.instance_of(TestController).post_process_exposed_object(object, :collection, false) { hooks << :post }
      get :test_data
      hooks.should == [:pre, :post]
    end

    it 'should correctly hook into singular responses' do
      object = {:a => 1, :b => 2}
      mock(TestController).test_data { object }
      hooks = []
      mock.instance_of(TestController).pre_process_exposed_object(object, :resource, true) { hooks << :pre }
      mock.instance_of(TestController).post_process_exposed_object(object, :resource, true) { hooks << :post }
      get :test_data
      hooks.should == [:pre, :post]
    end

    it 'should accept status options when rendering json' do
      stub(TestController).test_data    { {:hello => "World"} }
      stub(TestController).test_options { {:status => :created} }
      get :test_render_json
      response.status.should == 201
    end

    it 'should accept status options when responding with data' do
      stub(TestController).test_data    { {:hello => "World"} }
      stub(TestController).test_options { {:status => :created} }
      get :test_responds
      response.status.should == 201
    end

    it 'should accept status options when responding with a single object' do
      stub(TestController).test_data    { {:hello => "World"} }
      stub(TestController).test_options { {:status => :created} }
      get :test_data
      response.status.should == 201
    end

    it 'should accept status options when responding with a paginated collection' do
      stub(TestController).test_data do
        WillPaginate::Collection.create(1, 1) {|c| c.replace([{:hello => "World"}]); c.total_entries = 1 }
      end
      stub(TestController).test_options { {:status => :created} }
      get :test_data
      response.status.should == 201
    end

    it 'should accept status options when responding with collection' do
      stub(TestController).test_data    { [{:hello => "World"}] }
      stub(TestController).test_options { {:status => :created} }
      get :test_data
      response.status.should == 201
    end

    it 'should let you override the content type' do
      stub(TestController).test_data    { {:hello => "World"} }
      stub(TestController).test_options { {:content_type => Mime::HTML} }
      get :test_data
      response.headers['Content-Type'].should =~ /text\/html/
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

    describe 'hooking into the process' do

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

      before :each do
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

  describe 'caching' do

    let!(:controller_class)    { Class.new TestController }

    it 'should use a set for storing the cached actions' do
      controller_class.cached_actions.should be_a Set
      controller_class.cached_actions.should == Set.new
    end

    it 'should default the caching timeout' do
    end

    it 'should let you set the caching timeout' do
      expect do
        controller_class.caches :test_data, :cache_for => 10.minutes
        controller_class.caching_timeout.should == 10.minutes
      end.to change(controller_class, :caching_timeout)
    end

    it 'should let you set which actions should be cached' do
      controller_class.cached_actions.should be_empty
      controller_class.caches :test_data
      controller_class.cached_actions.should == ["test_data"].to_set
    end

    describe 'when dealing with the controller' do

      it 'should invoke the caching callback with caching enabled' do
        set_caching_to true do
          mock.instance_of(controller_class).cache_response.with_any_args
          get :test_data
        end
      end

      it 'should not invoke the caching callback with caching disabled' do
        set_caching_to false do
          dont_allow.instance_of(controller_class).cache_response.with_any_args
          get :test_data
        end
      end

      before :each do
        controller_class.caches :test_data
      end

      around :each do |t|
        set_caching_to true, &t
      end

      context 'with a singular response' do

        let(:cached_object) { Object.new }

        before :each do
          stub(RocketPants::Caching).cache_key_for(cached_object) { "my-object" }
          stub(RocketPants::Caching).etag_for(cached_object)      { "my-object:stored-etag" }
          stub(controller_class).test_data { cached_object }
        end

        it 'should invoke the caching callback correctly' do
          mock.instance_of(controller_class).cache_response cached_object, true
          get :test_data
        end

        it 'should not set the expires in time' do
          get :test_data
          response['Cache-Control'].to_s.should_not =~ /max-age=(\d+)/
        end

        it 'should set the response etag' do
          get :test_data
          response['ETag'].should == '"my-object:stored-etag"'
        end

      end

      context 'with a collection response' do

        let(:cached_objects) { [Object.new] }

        before :each do
          dont_allow(RocketPants::Caching).cache_key_for.with_any_args
          dont_allow(RocketPants::Caching).etag_for.with_any_args
          stub(controller_class).test_data { cached_objects }
        end

        it 'should invoke the caching callback correctly' do
          mock.instance_of(controller_class).cache_response cached_objects, false
          get :test_data
        end

        it 'should set the expires in time' do
          get :test_data
          response['Cache-Control'].to_s.should =~ /max-age=(\d+)/
        end

        it 'should not set the response etag' do
          get :test_data
          response["ETag"].should be_nil
        end

      end

    end

  end

  describe 'error handling' do

    let!(:controller_class) { Class.new(TestController) }
    let!(:logger)           { ::Logger.new(StringIO.new) }

    before :each do
      controller_class.logger = logger
    end

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

  end

  describe 'jsonp support' do

    let!(:first_controller) { Class.new(TestController)   }
    let!(:controller_class) { Class.new(first_controller) }

    it 'should let you specify requests as having jsonp' do
      controller_class.jsonp
      get :echo, :echo => "Hello World"
      response.content_type.should include 'application/json'
      response.body.should == %({"response":{"echo":"Hello World"}})
      get :echo, :echo => "Hello World", :callback => "test"
      response.content_type.should include 'application/javascript'
      response.body.should == %|test({"response":{"echo":"Hello World"}});|
    end

    it 'should automatically inherit it' do
      first_controller.jsonp :enable => true
      get :echo, :echo => "Hello World", :callback => "test"
      response.content_type.should include 'application/javascript'
      response.body.should == %|test({"response":{"echo":"Hello World"}});|
      get :echo, :echo => "Hello World", :other_callback => "test"
      response.content_type.should include 'application/json'
      response.body.should == %({"response":{"echo":"Hello World"}})
    end

    it 'should allow you to disable at a lower level' do
      first_controller.jsonp :enable => true
      controller_class.jsonp :enable => false
      get :echo, :echo => "Hello World", :callback => "test"
      response.content_type.should include 'application/json'
      response.body.should == %({"response":{"echo":"Hello World"}})
    end

    it 'should let you specify options to it' do
      controller_class.jsonp :parameter => 'cb'
      get :echo, :echo => "Hello World", :cb => "test"
      response.content_type.should include 'application/javascript'
      response.body.should == %|test({"response":{"echo":"Hello World"}});|
      get :echo, :echo => "Hello World", :callback => "test"
      response.content_type.should include 'application/json'
      response.body.should == %({"response":{"echo":"Hello World"}})
    end

    it 'should let you specify it on a per action level' do
      controller_class.jsonp :only => [:test_data]
      get :echo, :echo => "Hello World", :callback => "test"
      response.content_type.should include 'application/json'
      response.body.should == %({"response":{"echo":"Hello World"}})
      stub(controller_class).test_data { {"other" => true} }
      get :test_data, :callback => "test"
      response.content_type.should include 'application/javascript'
      response.body.should == %|test({"response":{"other":true}});|
    end

    it 'should not wrap non-get actions' do
      controller_class.jsonp
      post :echo, :echo => "Hello World", :callback => "test"
      response.content_type.should include 'application/json'
      response.body.should == %({"response":{"echo":"Hello World"}})
    end

    it 'should have the correct content length' do
      controller_class.jsonp
      get :echo, :echo => "Hello World", :callback => "test"
      response.content_type.should include 'application/javascript'
      response.body.should == %|test({"response":{"echo":"Hello World"}});|
      response.headers['Content-Length'].to_i.should == Rack::Utils.bytesize(response.body)
    end

  end

end