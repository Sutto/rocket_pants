TestRouter = ActionDispatch::Routing::RouteSet.new
TestRouter.draw do
  get  'echo', :to => 'test#echo'
  put  'echo', :to => 'test#echo'
  post 'echo', :to => 'test#echo'
  get  'echo_session', :to => 'test#echo_session'
  get  'echo_flash', :to => 'test#echo_flash'
  # Actual mockable endpoints
  get 'exception',        :to => 'test#demo_exception'
  get 'test_data',        :to => 'test#test_data'
  get 'test_error',       :to => 'test#test_error'
  get 'test_render_json', :to => 'test#test_render_json'
  get 'test_responds',    :to => 'test#test_responds'
  get 'test_metadata',    :to => 'test#test_metadata'
end
TestRouter.finalize!

class TestController < RocketPants::Base
  include TestRouter.url_helpers
  
  ErrorOfDoom = Class.new(StandardError)
  YetAnotherError = Class.new(ErrorOfDoom)
  
  version 1..2
  
  def self.test_data
  end

  def self.test_options
    {}
  end
  
  def self.test_error
    NotImplementedError
  end

  def echo
    expose :echo => params[:echo]
  end
  
  def echo_session
    expose :echo => session[:echo]
  end

  def echo_flash
    expose :echo => request.flash[:echo]
  end
  
  def demo_exception
    error! :throttled
  end

  def test_head
    head :created
  end
  
  def test_data
    expose self.class.test_data, self.class.test_options
  end

  def test_responds
    responds self.class.test_data, self.class.test_options
  end

  def test_render_json
    render_json self.class.test_data, self.class.test_options
  end
  
  def test_error
    raise self.class.test_error
  end

  def test_metadata
    expose({:test => true}, :metadata => params[:metadata])
  end

  def premature_termination
    error! :throtted
    exposes :finished => true
  end
  
end