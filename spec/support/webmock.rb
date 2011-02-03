require 'webmock'
require 'api_smith/web_mock_extensions'

module WebmockResponses
  include APISmith::WebMockExtensions
  
  FIXTURE_ROOT = File.expand_path('../../fixtures/', __FILE__)
  
  # Takes a named json fixture and returns the JSON content from
  # the file in the fixture directory, suitable for mocking out
  # the response or parsing for use with content checking.
  # @param [String] response_file the name (minus .json) of the response file to use
  def api_fixture_json(response_file)
    File.read(File.join(FIXTURE_ROOT, "#{response_file}.json"))
  end
  
  # Takes the response of stub_request from Webmock, a mock response name
  # and some extra data to mock out what the response should return.
  # @param [WebMock::RequestStub] api_stub the request stub to set the details on
  # @param [String] response_file the file name to use to get the json contents
  # @param [Hash] extra any extra options to pass to the to_return method on the api stub.
  def add_response_stub(api_stub, response_file, extra = {})
    json = api_fixture_json(response_file)
    api_stub.to_return({
      :status  => 200,
      :body    => json,
      :headers => {'Content-Type' => 'application/json'}
    }.merge(extra))
  end
  
  # Shorthand to stub out an api call with the given details.
  # @param [Symbol] method the http method to stub out or :any
  # @param [String] path The path (relative to the api endpoint) to stub
  # @param [String] response_file The name of the response file
  # @param [Hash] extra any extra options to pass to the response stub
  def stub_with_fixture(method, path, response_file, extra = {})
    add_response_stub stub_api(method, path), response_file, extra
  end
  
end