require 'spec_helper'

describe TestController, 'rspec integration', :integration => true, :target => 'rspec' do
  # Hack to allow us to include the ActionController::TestCase::Behaviour module
  def self.setup(*args); end
  def self.teardown(*args); end

  # Important to include behaviour before the RocketPants::TestHelpers
  include ActionController::TestCase::Behavior
  include RocketPants::TestHelper
  include RocketPants::RSpecMatchers

  default_version 1

  before do
    @routes     = TestRouter
    @controller = TestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  describe 'should have_exposed' do
    context "given a request with parameters" do
      it "allows you to asset what should have been exposed by an action" do
        get :echo, :echo => "ping"
        response.should have_exposed(:echo => "ping")
      end
    end
    context "given a request without parameters" do
      it "allows you to asset what should have been exposed by an action" do
        get :test_data
        request.params.should include(:version)
      end
    end
  end

  describe 'specifying a prefixed version' do
    after do
      response.should have_exposed(:echo => "ping")
    end

    it "gets the correct path when specifying a version of `2`" do
      get :echo, :echo => "ping", :version => 2
    end

    it "gets the correct path when specifying a version of `v2`" do
      get :echo, :echo => "ping", :version => 'v2'
    end
  end
end
