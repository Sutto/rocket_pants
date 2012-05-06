require 'spec_helper'

describe RocketPants::CacheMiddleware do
  include ControllerHelpers

  # Wrap the normal request in cache middleware.
  def request(action = :echo)
    @request = Rack::MockRequest.new(RocketPants::CacheMiddleware.new(controller_class.action(action)))
  end

  it 'should return the correct status with the rails default etags' do
    # Now, do the request
    get(:echo, {:echo => "same thing"}, {}, 'HTTP_IF_NONE_MATCH' => '"6f5d89fd787b63b076227b8ddcd27e27"')
    response.status.should == 200 # Not 304.
  end

end