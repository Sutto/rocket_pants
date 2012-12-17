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

  context 'api routes with prefix support' do

    before :each do
      draw_routes do
        api :version => 1, :allow_prefix => 'v' do
          get 'a', :to => 'test#echo'
        end
        api :versions => %w(2 3) do
          get 'b', :to => 'test#echo'
        end
        api :versions => %w(4 5), :require_prefix => 'v' do
          get 'c', :to => 'test#echo'
        end
      end
    end

    it 'should recognise a path with and without prefix when allow_prefix is given' do
      recognize_path('/v1/a').should == {:controller => 'test', :action => 'echo', :version => 'v1', :format => 'json', :rp_prefix => {:text => "v", :required => false}}
      recognize_path('/1/a').should == {:controller => 'test', :action => 'echo', :version => '1', :format => 'json', :rp_prefix => {:text => "v", :required => false}}
    end

    it 'should not recognise a path when prefix is given' do
      expect { recognize_path('/v2/b') }.to raise_error(ActionController::RoutingError)
      expect { recognize_path('/v3/b') }.to raise_error(ActionController::RoutingError)
      recognize_path('/2/b').should == {:controller => 'test', :action => 'echo', :version => '2', :format => 'json'}
      recognize_path('/3/b').should == {:controller => 'test', :action => 'echo', :version => '3', :format => 'json'}
    end

    it 'should recognise a path only with version when require_prefix is given' do
      recognize_path('/v4/c').should == {:controller => 'test', :action => 'echo', :version => 'v4', :format => 'json', :rp_prefix => {:text => "v", :required => true}}
      recognize_path('/v5/c').should == {:controller => 'test', :action => 'echo', :version => 'v5', :format => 'json', :rp_prefix => {:text => "v", :required => true}}
      expect { recognize_path('/4/c') }.to raise_error(ActionController::RoutingError)
      expect { recognize_path('/5/c') }.to raise_error(ActionController::RoutingError)
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