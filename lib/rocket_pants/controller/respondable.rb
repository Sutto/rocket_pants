module RocketPants
  module Respondable
    extend ActiveSupport::Concern

    RENDERING_OPTIONS = [:status, :content_type]

    private

    def default_serializer_options
      {
        url_options: url_options,
        root:        false
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

    # Exposes an object to the response - Essentiall, it tells the
    # controller that this is what we need to render.
    def exposes(object, options = {})
      pre_process_exposed_object object
      converter = RocketPants::Converters.fetch object, options
      metadata = metadata_for object, options, converter
      expose_metadata metadata
      response = metadata.merge(converter.response_key => converter.converted)
      render_json response, options
      post_process_exposed_object object
    end
    alias expose exposes

    # In RocketPants 2.0, all of these are handled via exposes calls.
    alias paginated  exposes
    alias resource   exposes
    alias collection exposes

    # Hooks in to allow you to perform pre-processing of objects
    # when they are exposed. Used for plugins to the controller.
    #
    # @param [Object] resource the exposed object.
    def pre_process_exposed_object(resource)
    end

    # Hooks in to allow you to perform post-processing of objects
    # when they are exposed. Used for plugins to the controller.
    #
    # @param [Object] resource the exposed object.
    def post_process_exposed_object(resource)
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
    def metadata_for(object, options, converter)
      {}.tap do |metadata|
        metadata.merge! converter.metadata
        metadata.merge! options[:metadata] if options[:metadata]
      end
    end

  end
end