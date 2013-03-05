require 'spec_helper'

describe TestController, 'rspec integration', :integration => true, :target => 'rspec' do
  # Hack to allow us to include the ActionController::TestCase::Behaviour module
  def self.setup(*args); end
  def self.teardown(*args); end

  # Important to include behaviour before the RocketPants::TestHelpers
  include ActionController::TestCase::Behavior
  include RocketPants::TestHelper
  include RocketPants::RSpecMatchers

  before do
    @routes     = TestRouter
    @controller = TestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  describe 'should have_exposed' do
    it "allows you to asset what should have been exposed by an action" do
      get :echo, :echo => "ping", :version => 1

      response.should have_exposed(:echo => "ping")
    end
  end
end
