require 'spec_helper'

describe RocketPants::Converters::Kaminari, integration: true, target: 'kaminari' do

  use_reversible_tables :users, scope: :all

  before :all do
    begin
      stderr, $stderr = $stderr, StringIO.new
      require 'kaminari'
      Kaminari::Hooks.init if defined?(Kaminari::Hooks.init)
    ensure
      $stderr = stderr
    end
    25.times { |i| User.create age: (18 + i) }
  end

  it 'should have the correct hierarchy' do
    described_class.should be < RocketPants::Converters::Collection
  end

  it 'should include pagination in metadata' do
    pager = Kaminari::PaginatableArray.new((1..200).to_a, limit: 10, offset: 10)
    metadata = described_class.new(pager, {}).metadata
    metadata[:count].should == pager.size
    metadata[:pagination].should be_present
    metadata[:pagination].should include({
      next: 3,
      current: 2,
      previous: 1,
      pages: 20,
      count: 200,
      per_page: 10
    })
  end

  it 'should have the correct body' do
    users = User.page(1).per(5)
    result = described_class.new(users, {}).convert
    result.should == users.map(&:serializable_hash)
  end

  context 'detecting support' do

    subject { described_class }

    it 'should not detect an array' do
      subject.should_not be_converts User.all.to_a, {}
      subject.should_not be_converts [1, 2, 3], {}
    end

    it 'should not detect a blank object' do
      subject.should_not be_converts [], {}
      subject.should_not be_converts nil, {}
    end

    it 'should detect a raw collection' do
      pager = Kaminari::PaginatableArray.new((1..200).to_a, limit: 10, offset: 10)
      subject.should be_converts pager, {}
    end

    it 'should detect a relation' do
      collection = User.page(1).per(5)
      subject.should be_converts collection, {}
    end

  end

end