module RocketPants
  module Respondable
    extend ActiveSupport::Concern

    def self.pagination_type(object)
      if defined?(WillPaginate::Collection) && object.is_a?(WillPaginate::Collection)
        :will_paginate
      elsif object.respond_to?(:num_pages) && object.respond_to?(:current_page)
        :kaminari
      else
        nil
      end
    end

    def self.paginated?(object)
      !pagination_type(object).nil?
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
          :next     => (current == total ? nil : (current + 1)),
          :per_page => per_page,
          :pages    => total,
          :count    => collection.total_count
        }
      end
    end

    def self.normalise_object(object, options = {})
      # Convert the object using a standard grape-like lookup chain.
      if object.is_a?(Array) || object.is_a?(Set)
        object.map { |o| normalise_object o, options }
      elsif object.respond_to?(:serializable_hash)
        object.serializable_hash options
      elsif object.respond_to?(:as_json)
        object.as_json options
      else
        object
      end
    end

    RENDERING_OPTIONS = [:status, :content_type]

    private

    def normalise_object(object, options = {})
      Respondable.normalise_object object, options.except(*RENDERING_OPTIONS)
    end

    # Given a json object or encoded json, will encode it
    # and set it to be the output of the given page.
    def render_json(json, options = {})
      # Setup data from options
      self.status       = options[:status] if options[:status]
      self.content_type = options[:content_type] if options[:content_type]
      options = options.slice(*RENDERING_OPTIONS)
      # Don't convert raw strings to JSON.
      json = ActiveSupport::JSON.encode(json) unless json.respond_to?(:to_str)
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

    # Renders a single resource.
    def resource(object, options = {})
      pre_process_exposed_object object, :resource, true
      render_json({
       :response => normalise_object(object, options)
      }, options)
      post_process_exposed_object object, :resource, true
    end

    # Renders a normal collection to JSON.
    def collection(collection, options = {})
      pre_process_exposed_object collection, :collection, false
      options = options.reverse_merge(:compact => true)
      render_json({
        :response => normalise_object(collection, options),
        :count    => collection.length
      }, options)
      post_process_exposed_object collection, :collection, false
    end

    # Renders a paginated collecton to JSON.
    def paginated(collection, options = {})
      pre_process_exposed_object collection, :paginated, false
      options = options.reverse_merge(:compact => true)
      render_json({
        :response   => normalise_object(collection, options),
        :count      => collection.length,
        :pagination => Respondable.extract_pagination(collection)
      }, options)
      post_process_exposed_object collection, :paginated, false
    end

    # Exposes an object to the response - Essentiall, it tells the
    # controller that this is what we need to render.
    def exposes(object, options = {})
      if Respondable.paginated?(object)
        paginated object, options
      elsif object.is_a?(Array)
        collection object, options
      else
        resource object, options
      end
    end
    alias expose exposes

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

  end
end