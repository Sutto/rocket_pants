module RocketPants
  module Respondable
    extend ActiveSupport::Concern

    SerializerWrapper = Struct.new(:serializer, :object) do

      def serializable_hash(options = {})
        instance = serializer.new(object, options)
        if instance.respond_to?(:serializable_hash)
          instance.serializable_hash
        else
          instance.as_json options
        end
      end

    end

    def self.pagination_type(object)
      if object.respond_to?(:total_entries)
        :will_paginate
      elsif object.respond_to?(:num_pages) && object.respond_to?(:current_page)
        :kaminari
      else
        nil
      end
    end

    def self.invalid?(object)
      object.respond_to?(:errors) && object.errors.present?
    end

    def self.paginated?(object)
      !pagination_type(object).nil?
    end

    def self.collection?(object)
      object.is_a?(Array) || object.respond_to?(:to_ary)
    end

    def self.extract_pagination(collection)
      case pagination_type(collection)
      when :will_paginate
        {
          :previous => collection.previous_page.try(:to_i),
          :next     => collection.next_page.try(:to_i),
          :current  => collection.current_page.try(:to_i),
          :per_page => collection.per_page.try(:to_i),
          :count    => collection.total_entries.try(:to_i),
          :pages    => collection.total_pages.try(:to_i)
        }
      when :kaminari
        current, total, per_page = collection.current_page, collection.num_pages, collection.limit_value
        {
          :current  => current,
          :previous => (current > 1 ? (current - 1) : nil),
          :next     => (current >= total ? nil : (current + 1)),
          :per_page => per_page,
          :pages    => total,
          :count    => collection.total_count
        }
      end
    end

    def self.normalise_object(object, options = {})
      # So we don't use the wrong options / modify them up the chain...
      options = options.dup

      # First, prepare the object for serialization.
      object = normalise_to_serializer object, options

      # Convert the object using a standard grape-like lookup chain.
      if object.respond_to?(:to_ary) || object.is_a?(Set) || (options[:each_serializer] && !options[:serializer])
        suboptions = options.dup
        if each_serializer = suboptions.delete(:each_serializer)
          suboptions[:serializer] = each_serializer
        end
        object.map { |o| normalise_object o, suboptions }
      elsif object.respond_to?(:serializable_hash)
        object.serializable_hash options
      elsif object.respond_to?(:as_json)
        object.as_json options
      else
        object
      end
    end

    def self.normalise_to_serializer(object, options)
      return object unless RocketPants.serializers_enabled?
      serializer = options.delete(:serializer)
      # AMS overrides active_model_serializer, so we ignore it and tell it to go away, generally...
      serializer = object.active_model_serializer if object.respond_to?(:active_model_serializer) && serializer.nil? && !object.respond_to?(:to_ary)
      return object unless serializer
      SerializerWrapper.new serializer, object
    end

    RENDERING_OPTIONS = [:status, :content_type]

    private

    def normalise_object(object, options = {})
      Respondable.normalise_object object, options.except(*RENDERING_OPTIONS).reverse_merge(default_serializer_options)
    end

    def default_serializer_options
      {
        :url_options => url_options,
        :root        => false
      }
    end

    def encode_to_json(object)
      ActiveSupport::JSON.encode object
    end

    # Given a json object or encoded json, will encode it
    # and set it to be the output of the given page.
    def render_json(json, options = {})
      # Setup data from options
      self.status       = options[:status] if options[:status]
      self.content_type = options[:content_type] if options[:content_type]
      options = options.slice(*RENDERING_OPTIONS)
      # Don't convert raw strings to JSON.
      json = encode_to_json(json) unless json.respond_to?(:to_str)
      # Encode the object to json.
      self.status        ||= :ok
      self.content_type  ||= Mime::JSON
      self.response_body   = json
      headers['Content-Length'] = Rack::Utils.bytesize(json).to_s
    end

    # Renders a raw object, without any wrapping etc.
    # Suitable for nicer object handling.
    def responds(object, options = {})
      render_json normalise_object(object, options), options
    end

    def respond_with_object_and_type(object, options, type, singular)
      pre_process_exposed_object object, type, singular
      options = options.reverse_merge(:singular => singular)
      options = options.reverse_merge(:compact => true) unless singular
      meta = expose_metadata metadata_for(object, options, type, singular)
      render_json({:response => normalise_object(object, options)}.merge(meta), options)
      post_process_exposed_object object, type, singular
    end

    # Renders a single resource.
    def resource(object, options = {})
      respond_with_object_and_type object, options, :resource, true
    end

    # Renders a normal collection to JSON.
    def collection(collection, options = {})
      respond_with_object_and_type collection, options, :collection, false
    end

    # Renders a paginated collecton to JSON.
    def paginated(collection, options = {})
      respond_with_object_and_type collection, options, :paginated, false
    end

    # Exposes an object to the response - Essentiall, it tells the
    # controller that this is what we need to render.
    def exposes(object, options = {})
      if Respondable.paginated?(object)
        paginated object, options
      elsif Respondable.collection?(object)
        collection object, options
      else
        if Respondable.invalid?(object)
          error! :invalid_resource, object.errors
        else
          resource object, options
        end
      end
    end
    alias expose exposes

    # Fixes head to return the correct content type for you api.
    #
    # See the ActionController build in version for definitions.
    def head(status, options = {})
      super status, options.merge(content_type: 'application/json')
    end

    # Hooks in to allow you to perform pre-processing of objects
    # when they are exposed. Used for plugins to the controller.
    #
    # @param [Object] resource the exposed object.
    # @param [Symbol] type the type of object exposed, one of :resource, :collection or :paginated
    # @param [true,false] singular Whether or not the given object is singular (e.g. :resource)
    def pre_process_exposed_object(resource, type, singular)
    end

    # Hooks in to allow you to perform post-processing of objects
    # when they are exposed. Used for plugins to the controller.
    #
    # @param [Object] resource the exposed object.
    # @param [Symbol] type the type of object exposed, one of :resource, :collection or :paginated
    # @param [true,false] singular Whether or not the given object is singular (e.g. :resource)
    def post_process_exposed_object(resource, type, singular)
    end

    # Given a hash of request metadata, will:
    # 1. Do anything special with the request metadata
    # 2. Return the hash, suitable for merging into the response hash
    # 3. Start a dance party.
    #
    # @param  [Hash{Symbol => Object}] metadata the hash of the request metadata.
    # @return [Hash{Symbol => Object}] the passed in metadata
    def expose_metadata(metadata)
      metadata
    end

    # Extracts the metadata for the current response, merging in options etc.
    # Implements a simple hook to allow adding extra metadata to your api.
    #
    # @param [Object] object the data being exposed
    # @param [Hash{Symbol => Object}] options expose options optionally including new metadata.
    # @param [Symbol] type the type of the current object
    # @param [true,false] singular true iff the current object is a singular resource
    def metadata_for(object, options, type, singular)
      {}.tap do |metadata|
        metadata[:count]      = object.length unless singular
        metadata[:pagination] = Respondable.extract_pagination(object) if type == :paginated
        metadata.merge! options[:metadata] if options[:metadata]
      end
    end

  end
end