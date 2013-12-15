require 'spec_helper'

describe RocketPants::Converters::Base do

  it 'should always support items' do
    described_class.should be_converts Object.new, {}
    described_class.should be_converts 1, {}
    described_class.should be_converts "Hello World", {}
  end

  it 'should pass through the item' do
    object = Object.new
    described_class.new(object, {}).convert.should == object
  end

  it 'should have no metadata' do
    object = Object.new
    described_class.new(object, {x: 1}).metadata.should == {}
  end

  it 'should have the default response key' do
    object = Object.new
    described_class.new(object, {x: 1}).response_key.should == 'response'
  end

end