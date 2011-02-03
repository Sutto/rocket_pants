require 'webmock'
require 'api_smith/web_mock_extensions'

module WebmockResponses
  include APISmith::WebMockExtensions
  
  FIXTURE_ROOT = File.expand_path('../../fixtures/', __FILE__)
  
  def api_fixture_json(response_file)
    File.read(File.join(FIXTURE_ROOT, "#{response_file}.json"))
  end
  
  def add_response_stub(api_stub, response_file, extra = {})
    json = api_fixture_json(response_file)
    api_stub.to_return({
      :status  => 200,
      :body    => json,
      :headers => {'Content-Type' => 'application/json'}
    }.merge(extra))
  end
  
  def stub_with_fixture(method, url, response_file, extra = {})
    add_response_stub stub_api(method, url), response_file, extra
  end
  
end