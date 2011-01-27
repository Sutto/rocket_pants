require 'will_paginate/collection'

module RocketPants
  module Respondable
    extend ActiveSupport::Concern
    
    module InstanceMethods
      
      protected
      
      def normalise_object(object, options = {})
        # Convert the object using a standard grape-like lookup chain.
        if object.respond_to?(:serializable_hash)
          object.serializable_hash options
        elsif object.respond_to?(:as_json)
          object.as_json options
        elsif object.is_a?(Array) || object.is_a?(Set)
          object.map { |o| normalise_object o, options }
        else
          object
        end
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
      
      # Renders a single resource.
      def resource(object, options = {})
        render_json({
         :response => normalise_object(object, options) 
        })
      end

      # Renders a normal collection to JSON.
      def collection(collection, options = {})
        render_json({
          :response => normalise_object(collection, options),
          :count    => collection.length
        })
      end
      
      # Renders a paginated collecton to JSON.
      def paginated(collection, options = {})
        render_json({
          :response   => normalise_object(collection, options),
          :count      => collection.length,
          :pagination => {
            :previous => collection.previous_page,
            :next     => collection.next_page,
            :current  => collection.current_page,
            :per_page => collection.per_page,
            :count    => collection.total_entries,
            :pages    => collection.total_pages
          }
        })
      end

      # Exposes an object to the response - Essentiall, it tells the
      # controller that this is what we need to render.
      def exposes(object, options = {})
        case object
        when WillPaginate::Collection
          paginated object
        when Array
          collection object
        else
          resource object
        end
      end
      alias expose exposes
      
    end
  end
end