require 'spec_helper'

describe RocketPants::Routing do

  let(:router) { ActionDispatch::Routing::RouteSet.new }

  def draw_routes(&blk)
    router.draw(&blk)
    router.finalize!
  end

  def recognize_path(path, env = {})
    router.recognize_path(path, env)
  end

  def expect_options(*args)
    expect do
      router.draw do
        api(*args) do
          get 'echo', :to => 'test#echo'
        end
      end
    end
  end

  context 'a basic set of api routes' do

    before :each do
      draw_routes do
        api :version => 1 do
          get 'a', :to => 'test#echo'
        end
        api :versions => %w(2 3) do
          get 'b', :to => 'test#echo'
        end
      end
    end

    it 'should recognise a path to a single version' do
      recognize_path('/1/a').should == {:controller => 'test', :action => 'echo', :version => '1', :format => 'json'}
      recognize_path('/2/b').should == {:controller => 'test', :action => 'echo', :version => '2', :format => 'json'}
      recognize_path('/3/b').should == {:controller => 'test', :action => 'echo', :version => '3', :format => 'json'}
    end

    it 'should not recognise a path to other versions' do
      expect { recognize_path('/1/b') }.to raise_error(ActionController::RoutingError)
      expect { recognize_path('/2/a') }.to raise_error(ActionController::RoutingError)
      expect { recognize_path('/3/a') }.to raise_error(ActionController::RoutingError)
    end

  end

  it 'should not let you draw a route without a version' do
    expect_options.to raise_error(ArgumentError)
    expect_options(:version => []).to raise_error(ArgumentError)
    expect_options(:version => %w()).to raise_error(ArgumentError)
    expect_options(:version => nil).to raise_error(ArgumentError)
    expect_options(:version => []).to raise_error(ArgumentError)
    expect_options(:version => %w()).to raise_error(ArgumentError)
    expect_options(:versions => nil).to raise_error(ArgumentError)
    expect_options(:versions => []).to raise_error(ArgumentError)
    expect_options(:versions => %w()).to raise_error(ArgumentError)
  end

  it 'should not let you draw a route with an invalid version' do
    expect_options(:version => '  ').to raise_error(ArgumentError)
    expect_options(:version => '1.1').to raise_error(ArgumentError)
    expect_options(:version => 'test-version').to raise_error(ArgumentError)
    expect_options(:version => 'v1').to raise_error(ArgumentError)
  end

  it 'should not let you draw a route with an invalid version in multiple versions' do
    expect_options(:versions => ['', '2', '  ']).to raise_error(ArgumentError)
    expect_options(:versions => %w(1 . 1)).to raise_error(ArgumentError)
    expect_options(:versions => [1, 'a', 2]).to raise_error(ArgumentError)
    expect_options(:versions => %w(v1 v2)).to raise_error(ArgumentError)
  end

end