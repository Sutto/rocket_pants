require 'spec_helper'

describe RocketPants::Converters::WillPaginate, integration: true, target: 'will_paginate' do

  use_reversible_tables :users, scope: :all

  before :all do
    require 'will_paginate/active_record'
    require 'will_paginate/collection'
    25.times { |i| User.create age: (18 + i) }
  end

  it 'should have the correct hierarchy' do
    described_class.should be < RocketPants::Converters::Collection
  end

  it 'should include pagination in metadata' do
    pager = WillPaginate::Collection.create(2, 10) { |p| p.replace %w(a b c d e f g h i j); p.total_entries = 200 }
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
    users = User.paginate(page: 1, per_page: 5)
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
      pager = WillPaginate::Collection.create(2, 10) { |p| p.replace %w(a b c d e f g h i j); p.total_entries = 200 }
      subject.should be_converts pager, {}
    end

    it 'should detect a relation' do
      collection = User.page(1).per_page(5)
      subject.should be_converts collection, {}
    end

    it 'should detect a normally paginated result' do
      collection = User.paginate page: 1, per_page: 10
      subject.should be_converts collection, {}
    end

  end

end