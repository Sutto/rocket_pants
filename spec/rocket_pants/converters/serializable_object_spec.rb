require 'spec_helper'

describe RocketPants::Converters::SerializableObject do

  use_reversible_tables :users, scope: :all

  let!(:user) { User.create! age: 23 }

  it 'should have the correct hierarchy' do
    described_class.should be < RocketPants::Converters::Base
  end

  context 'detection' do

    subject { described_class }
    let(:options) { {} }

    it 'should not detect arrays' do
      subject.should_not be_converts User.all.to_a, options
    end

    it 'should not detect activerecord relations' do
      subject.should_not be_converts User.where('id IS NOT NULL'), options
    end

    it 'should not detect hashes' do
      subject.should_not be_converts({x: 1, y: 2}, options)
    end

    it 'should not detect other objects' do
      subject.should_not be_converts 1, options
      subject.should_not be_converts Object.new, options
      subject.should_not be_converts true, options
      subject.should_not be_converts false, options
    end

    it 'should detect individual records' do
      subject.should be_converts User.first!, options
    end

    it 'should support serializable object' do
      object = Object.new
      def object.serializable_object(*); {x: 1}; end
      subject.should be_converts object, {}
    end

    it 'should support serializable hash' do
      object = Object.new
      def object.serializable_hash(*); {x: 1}; end
      subject.should be_converts object, {}
    end

  end

  context 'conversion' do

    it 'should have no metadata' do
      described_class.new(user, {}).metadata.should == {}
    end

    it 'should serialize using serializable hash' do
      object = Object.new
      mock(object).serializable_hash(compact: true) { {x: 1} }
      described_class.new(object, compact: true).convert.should == {x: 1}
    end

    it 'should serialize using serializable object' do
      object = Object.new
      mock(object).serializable_object(compact: true) { {x: 1} }
      described_class.new(object, compact: true).convert.should == {x: 1}
    end

    it 'should work with a activerecord object' do
      described_class.new(user, {}).convert.should == user.serializable_hash
    end

  end

end