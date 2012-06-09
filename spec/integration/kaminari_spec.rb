require 'spec_helper'

describe RocketPants::Base, 'kaminari integration', :integration => true, :target => 'kaminari' do
  include ControllerHelpers

  before :all do
    begin
      stderr, $stderr = $stderr, StringIO.new
      require 'kaminari'
    ensure
      $stderr = stderr
    end
  end

  describe 'on models' do

    let(:table_manager) { ReversibleData.manager_for(:users) }

    before :all do
      table_manager.up!
      25.times { |i| User.create :age => (18 + i) }
    end

    after(:all) do
      User.delete_all
      table_manager.down!
    end

    it 'should let you expose a kaminari-paginated collection' do
      mock(TestController).test_data { User.page(1).per(5) }
      get :test_data
      content[:response].should be_present
      content[:count].should == 5
      content[:pagination].should be_present
      content[:pagination][:count].should == 25
    end

    it 'should not expose non-paginated as paginated' do
      mock(TestController).test_data { User.all }
      get :test_data
      content[:response].should be_present
      content[:count].should == 25
      content[:pagination].should_not be_present
    end

  end

  describe 'on arrays' do

    it 'should correctly convert a kaminari array' do
      pager = Kaminari::PaginatableArray.new((1..200).to_a, :limit => 10, :offset => 10)
      mock(TestController).test_data { pager }
      get :test_data
      content.should have_key(:pagination)
      content[:pagination].should == {
        :next => 3,
        :current => 2,
        :previous => 1,
        :pages => 20,
        :count => 200,
        :per_page => 10
      }.stringify_keys
      content.should have_key(:count)
      content[:count].should == 10
    end

  end

end