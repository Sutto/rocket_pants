require 'spec_helper'

describe RocketPants::Converters::Collection do

  use_reversible_tables :users, scope: :all

  let!(:user) { User.create! age: 23 }

  it 'should have the correct hierarchy' do
    described_class.should be < RocketPants::Converters::Base
  end

  context 'detection' do

    subject { described_class }
    let(:options) { {} }

    it 'should detect arrays' do
      subject.should be_converts User.all.to_a, options
    end

    it 'should detect activerecord relations' do
      subject.should be_converts User.where('id IS NOT NULL'), options
    end

    it 'should detect items implementing .to_ary' do
      item = Object.new
      def item.to_ary; []; end
      subject.should be_converts item, options
    end

    it 'should not detect hashes' do
      subject.should_not be_converts({x: 1, y: 2}, options)
    end

    it 'should not detect individual records' do
      subject.should_not be_converts User.first!, options
    end

    it 'should not detect other objects' do
      subject.should_not be_converts 1, options
      subject.should_not be_converts Object.new, options
      subject.should_not be_converts true, options
      subject.should_not be_converts false, options
    end

  end

  it 'should serialize the individual options' do
    result = Object.new
    mock(RocketPants::Converters).serialize_single(user, anything) { result }
    converted = described_class.new([user], {}).convert
    converted.should be_a Array
    converted.should == [result]
  end

  it 'should work with an empty array' do
    described_class.new([], {}).convert.should == []
  end

  it 'should pass the options to the children' do
    result = Object.new
    mock(RocketPants::Converters).serialize_single(user, {compact: true}) { result }
    converted = described_class.new([user], {compact: true}).convert
    converted.should be_a Array
    converted.should == [result]
  end

  it 'should include count in metadata' do
    described_class.new([], {}).metadata.should include count: 0
    described_class.new([1], {}).metadata.should include count: 1
    described_class.new([10, 11, 12], {}).metadata.should include count: 3
  end

end