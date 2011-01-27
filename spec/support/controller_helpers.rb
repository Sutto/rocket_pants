module ControllerHelpers
  
  def controller_class
    TestController
  end
  
  def request(action = :echo)
    @request || Rack::MockRequest.new(controller_class.action(action))
  end
  
  def response
    @response ||= nil
  end
  
  def get(action_name, params = {}, path_parameters = {})
    @request = request(action_name)
    path_parameters[:version] = 1 unless path_parameters.has_key?(:version)
    @content = nil
    @response = @request.get('/', :params => params, 'action_dispatch.request.path_parameters' => path_parameters)
  end
  
  def post(action_name, params = {}, path_parameters = {})
    @request = request(action_name)
    path_parameters[:version] = 1 unless path_parameters.has_key?(:version)
    @content = nil
    @response = @request.post('/', :params => params, 'action_dispatch.request.path_parameters' => path_parameters)
  end
  
  def content
    @content ||= ActiveSupport::JSON.decode(response.body).with_indifferent_access
  end
  
end