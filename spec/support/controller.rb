TestRouter = ActionDispatch::Routing::RouteSet.new
TestRouter.draw do
  get 'echo', :to => 'test#echo'
  put 'echo', :to => 'test#echo'
  post 'echo', :to => 'test#echo'
  get 'exception', :to => 'test#demo_exception'
  get 'test_data', :to => 'test#test_data'
end
TestRouter.finalize!

class TestController < RocketPants::Base
  include TestRouter.url_helpers
  
  version 1..2
  
  def self.test_data
  end
  
  def echo
    expose :echo => params[:echo]
  end
  
  def demo_exception
    error! :throttled
  end
  
  def test_data
    expose self.class.test_data
  end
  
  def premature_termination
    error! :throtted
    exposes :finished => true
  end
  
end