require 'spec_helper'
require 'rocket_pants/presenter'

describe RocketPants::Presenter do
  include ControllerHelpers

  use_reversible_tables :fish, :scope => :all

  it 'should provide an attr_exposed method on an AR model' do
    Fish.respond_to?(:attr_expose).should be_true
  end

  it 'should only expose certain attributes' do
    attrs = {:token => "a", :name => "Test Fish", :latin_name => "Latin Name", :child_number => 5}

    Fish.attr_expose :name

    f = Fish.create! attrs
    f.serializable_hash.keys.should == ["name"]
  end
end