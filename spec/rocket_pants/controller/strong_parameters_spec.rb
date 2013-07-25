require 'spec_helper'

describe RocketPants::Base, 'strong parameters integration' do
  include ControllerHelpers

  let!(:controller_class) { Class.new(TestController) }

  it "should have action controller parameters in controller" do
    action_is { raise "no action controller parameters" unless params.is_a? ActionController::Parameters }
    expect { get :test_data }.to_not raise_error
  end

  it "should map parameter missing error to bad request" do
    mock(controller_class).test_error { raise ActionController::ParameterMissing.new :foo }

    with_config :pass_through_errors, false do
      get :test_error
      content[:error].should == "bad_request"
      content[:error_description].should == "param not found: foo"
      response.should be_bad_request
    end
  end

  it "should map unpermitted parameters error to bad request" do
    mock(controller_class).test_error { raise ActionController::UnpermittedParameters.new [:foo, :bar] }

    with_config :pass_through_errors, false do
      get :test_error
      content[:error].should == "bad_request"
      content[:error_description].should == "found unpermitted parameters: foo, bar"
      response.should be_bad_request
    end
  end
end
