require 'will_paginate/collection'

module RocketPants
  module Respondable
    extend ActiveSupport::Concern

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

    module InstanceMethods

      private

      def normalise_object(object, options = {})
        Respondable.normalise_object object, options
      end

      # Given a json object or encoded json, will encode it
      # and set it to be the output of the given page.
      def render_json(json, options = {})
        # Don't convert raw strings to JSON.
        json = ActiveSupport::JSON.encode(json) unless json.respond_to?(:to_str)
        # Encode the object to json.
        self.status        ||= :ok
        self.content_type    = Mime::JSON
        self.response_body   = json
      end

      # Renders a raw object, without any wrapping etc.
      # Suitable for nicer object handling.
      def respond_with(object, options = {})
        render_json normalise_object(object, options)
      end

      # Renders a single resource.
      def resource(object, options = {})
        pre_process_exposed_object object, :resource, true
        render_json({
         :response => normalise_object(object, options)
        })
        post_process_exposed_object object, :resource, true
      end

      # Renders a normal collection to JSON.
      def collection(collection, options = {})
        pre_process_exposed_object collection, :collection, false
        options = options.reverse_merge(:compact => true)
        render_json({
          :response => normalise_object(collection, options),
          :count    => collection.length
        })
        post_process_exposed_object collection, :collection, false
      end

      # Renders a paginated collecton to JSON.
      def paginated(collection, options = {})
        pre_process_exposed_object collection, :paginated, false
        options = options.reverse_merge(:compact => true)
        render_json({
          :response   => normalise_object(collection, options),
          :count      => collection.length,
          :pagination => {
            :previous => collection.previous_page.try(:to_i),
            :next     => collection.next_page.try(:to_i),
            :current  => collection.current_page.try(:to_i),
            :per_page => collection.per_page.try(:to_i),
            :count    => collection.total_entries.try(:to_i),
            :pages    => collection.total_pages.try(:to_i)
          }
        })
        post_process_exposed_object collection, :paginated, false
      end

      # Exposes an object to the response - Essentiall, it tells the
      # controller that this is what we need to render.
      def exposes(object, options = {})
        case object
        when WillPaginate::Collection
          paginated object, options
        when Array
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
end