require 'spec_helper'
require 'minitest/mock'
require 'pry'

describe RocketPants::Caching do

  let(:object) do
    obj = Object.new
    obj.define_singleton_method(:id) do
      10
    end
    obj.define_singleton_method(:cache_key) do
      10
    end
    obj
  end
  let(:cache_key) { 'my-cache-key'}

  describe 'dealing with the etag cache' do
    before do
      allow(object).to receive(:cache_key) { 'hello' }
      allow(RocketPants::Caching).to receive(:cache_key_for).with(object) { cache_key }
    end
    it 'should let you remove an item from the cache' do
      RocketPants.cache[cache_key] = 'hello there'
      RocketPants::Caching.remove(object)
      RocketPants.cache[cache_key].should be_nil
    end
    
    it 'should safely delete a non-existant item from the cache' do
      expect do
        RocketPants::Caching.remove(object)
      end.to_not raise_error
    end
    
    it 'should let you record an object in the cache with a cache_key method' do
      RocketPants::Caching.record(object)
      RocketPants.cache[cache_key].should == Digest::MD5.hexdigest('hello')
    end
    
    xit 'should let you record an object in the cache with the default inspect value' do
      RocketPants::Caching.record object
      RocketPants.cache[cache_key].should == Digest::MD5.hexdigest(object.inspect)
    end
  end
  
  describe 'computing the cache key for an object' do
    
    it 'should return a md5-like string' do
      RocketPants::Caching.cache_key_for(object).should =~ /\A[a-z0-9]{32}\Z/
    end
    
    it 'should use the rp_object_key method if present' do
      object.define_singleton_method(:rp_object_key) { 'hello' }
      RocketPants::Caching.cache_key_for(object).should == Digest::MD5.hexdigest('hello')
    end
    
    it 'should build a default cache key for records with new? that are new' do
      object.define_singleton_method(:new?) { true }
      RocketPants::Caching.cache_key_for(object).should == Digest::MD5.hexdigest('Object/new')
    end
    
    it 'should build a default cache key for records with new? that are old' do
      object.define_singleton_method(:new?) { false }
      RocketPants::Caching.cache_key_for(object).should == Digest::MD5.hexdigest('Object/10')
    end
    
    it 'should build a default cache key for records without new' do
      RocketPants::Caching.cache_key_for(object).should == Digest::MD5.hexdigest('Object/10')
    end
  end
  
  describe 'normalising an etag' do
    
    it 'should correctly convert it to the string' do
      object.define_singleton_method(:to_s) { 'Hello-World' }
      described_class.normalise_etag(object).should == '"Hello-World"'
    end
    
    it 'should correctly deal with a basic case' do
      described_class.normalise_etag('SOMETAG').should == '"SOMETAG"'
    end
  end
  
  describe 'fetching an object etag' do
    before do
      allow(RocketPants::Caching).to receive(:cache_key_for).with(object) { cache_key }
    end
    
    xit 'should use the cache key as a prefix' do
      RocketPants::Caching.etag_for(object).should =~ /\Amy-cache-key\:/
    end
    
    it 'should fetch the recorded etag' do
      allow(RocketPants).to receive(:cache) { { 'my-cache-key' => 'hello-world'} }
      RocketPants::Caching.etag_for(object)
    end
    
    xit 'should generate a new etag if one does not exist' do
      allow(RocketPants::Caching).to receive(:record).with(object) { cache_key }
      allow(RocketPants).to receive(:cache) { { 'my-cache-key' => nil} }
      RocketPants::Caching.etag_for object
    end
  end
end