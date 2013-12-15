require 'spec_helper'
require 'active_model_serializers'

describe RocketPants::Converters::AMS, integration: true, target: 'active_model_serializers' do

  use_reversible_tables :fish, scope: :each

  let(:fish) { Fish.create! name: "Test Fish", latin_name: "Fishus fishii", child_number: 1, token: "xyz" }

  it 'should have the correct hierarchy' do
    described_class.should be < RocketPants::Converters::Base
  end

  class SerializerA < ActiveModel::Serializer
    attributes :name, :latin_name
  end

  class SerializerB < ActiveModel::Serializer
    attributes :name, :child_number
  end


  context 'detection' do

    subject { described_class }
    let(:options) { {} }

    it 'should support objects with a specified serializer' do
      o = Object.new
      described_class.should_not be_converts o, options
      described_class.should be_converts o, options.merge(serializer: SerializerA)
    end

    it 'should support objects with a serializer via the active_model_serializer' do
      o = Object.new
      described_class.should_not be_converts o, options
      def o.active_model_serializer; SerializerA; end
      described_class.should be_converts o, options
    end

    it 'should not support blank objects' do
      described_class.should_not be_converts Object.new, options
    end

    it 'should not serialize the object when the active_model_serializer method returns nil' do
      o = Object.new
      def o.active_model_serializer; end
      described_class.should_not be_converts o, options
    end

  end

  context 'conversion' do

    it 'should proxy the AMS metadata'

    it 'should work with an array serializer'

    it 'should work with a specified serializer'

    it 'should work with the serializer from active_model_serializer'

    it 'should work with default serializer by name'

  end

end