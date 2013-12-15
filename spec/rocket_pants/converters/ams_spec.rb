require 'spec_helper'

describe RocketPants::Converters::AMS, integration: true, target: 'active_model_serializers' do

  use_reversible_tables :users, scope: :all

  let!(:user) { User.create! age: 23 }

  it 'should have the correct hierarchy' do
    described_class.should be < RocketPants::Converters::Base
  end

  context 'detection' do

    subject { described_class }
    let(:options) { {} }

    it 'should support objects with a matched serializer class'

    it 'should support objects with a specified serializer'

    it 'should support objects with a serializer via the active_model_serializer'

  end

  context 'conversion' do

    it 'should proxy the AMS metadata'

    it 'should work with an array serializer'

    it 'should work with a specified serializer'

    it 'should work with the serializer from active_model_serializer'

    it 'should work with default serializer by name'

  end

end