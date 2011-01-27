class TestController < RocketPants::Base
  
  def echo
    expose :echo => params[:echo]
  end
  
end