require 'spec_helper'

describe RocketPants::HeaderMetadata do
  include ControllerHelpers

  context 'metadata' do

    let(:table_manager) { ReversibleData.manager_for(:users) }

    before(:each) { table_manager.up! }
    after(:each)  { table_manager.down! }

    let(:users) do
      1.upto(5) do |offset|
        User.create :age => (18 + offset)
      end
      User.all
    end

    it 'should not include header metadata by default' do
      mock(TestController).test_data { users }
      get :test_data
      response.headers.should_not have_key 'X-Api-Count'
    end

    it 'should let you turn on header metadata' do
      with_config :header_metadata, true do
        mock(TestController).test_data { users }
        get :test_data
        response.headers.should have_key 'X-Api-Count'
        response.headers['X-Api-Count'].should == users.size.to_s
      end
    end

    it 'should handle nested (e.g. pagination) metadata correctly' do
      with_config :header_metadata, true do
        pager = WillPaginate::Collection.create(2, 10) { |p| p.replace %w(a b c d e f g h i j); p.total_entries = 200 }
        mock(TestController).test_data { pager }
        get :test_data
        h = response.headers
        h['X-Api-Pagination-Next'].should     == '3'
        h['X-Api-Pagination-Current'].should  == '2'
        h['X-Api-Pagination-Previous'].should == '1'
        h['X-Api-Pagination-Pages'].should    == '20'
        h['X-Api-Pagination-Count'].should    == '200'
        h['X-Api-Pagination-Per-Page'].should == '10'
        h['X-Api-Count'].should               == '10'
      end
    end

  end

end