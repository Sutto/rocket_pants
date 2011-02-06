require 'spec_helper'

describe RocketPants::Caching do
  
  let(:object) { Object.new.tap { |i| stub(i).id.returns(10) } }
  
  describe 'dealing with the etag cache' do
    
    it 'should let you remove an item from the cache' do
      stub(RocketPants::Caching).cache_key_for(object) { 'my-cache-key' }
      RocketPants.cache['my-cache-key'] = 'hello there'
      RocketPants::Caching.remove object
      RocketPants.cache['my-cache-key'].should be_nil
    end
    
    it 'should safely delete a non-existant item from the cache' do
      expect do
        RocketPants::Caching.remove object
      end.to_not raise_error
    end
    
    it 'should let you record an object in the cache with a cache_key method' do
      mock(RocketPants::Caching).cache_key_for(object) { 'my-cache-key' }
      mock(object).cache_key { 'hello' }
      RocketPants::Caching.record object
      RocketPants.cache['my-cache-key'].should == Digest::MD5.hexdigest('hello')
    end
    
    it 'should let you record an object in the cache with the default inspect value' do
      mock(RocketPants::Caching).cache_key_for(object) { 'my-cache-key' }
      RocketPants::Caching.record object
      RocketPants.cache['my-cache-key'].should == Digest::MD5.hexdigest(object.inspect)
    end
    
  end
  
  describe 'computing the cache key for an object' do
    
    it 'should return a md5-like string' do
      RocketPants::Caching.cache_key_for(object).should =~ /\A[a-z0-9]{32}\Z/
    end
    
    it 'should use the rp_object_key method if present' do
      mock(object).rp_object_key { 'hello' }
      RocketPants::Caching.cache_key_for(object).should == Digest::MD5.hexdigest('hello')
    end
    
    it 'should build a default cache key for records with new? that are new' do
      mock(object).new? { true }
      RocketPants::Caching.cache_key_for(object).should == Digest::MD5.hexdigest('Object/new')
    end
    
    it 'should build a default cache key for records with new? that are old' do
      mock(object).new? { false }
      RocketPants::Caching.cache_key_for(object).should == Digest::MD5.hexdigest('Object/10')
    end
    
    it 'should build a default cache key for records without new' do
      RocketPants::Caching.cache_key_for(object).should == Digest::MD5.hexdigest('Object/10')
    end
    
  end
  
  describe 'normalising an etag' do
    
    it 'should correctly convert it to the string' do
      def object.to_s; 'Hello-World'; end
      mock(object).to_s { 'Hello-World' }
      described_class.normalise_etag(object).should == '"Hello-World"'
    end
    
    it 'should correctly deal with a basic case' do
      described_class.normalise_etag('SOMETAG').should == '"SOMETAG"'
    end
    
  end
  
  describe 'fetching an object etag' do
    
    before :each do
      stub(RocketPants::Caching).cache_key_for(object) { 'my-cache-key' }
    end
    
    it 'should use the cache key as a prefix' do
      RocketPants::Caching.etag_for(object).should =~ /\Amy-cache-key\:/
    end
    
    it 'should fetch the recorded etag' do
      mock(RocketPants.cache)['my-cache-key'].returns 'hello-world'
      RocketPants::Caching.etag_for(object)
    end
    
    it 'should generate a new etag if one does not exist' do
      mock(RocketPants::Caching).record object, 'my-cache-key'
      stub(RocketPants.cache)['my-cache-key'].returns nil
      RocketPants::Caching.etag_for object
    end
    
  end
  
end