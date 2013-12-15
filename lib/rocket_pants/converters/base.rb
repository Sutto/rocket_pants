module RocketPants
  module Converters
    class Base

      def self.converts?(object, options)
        true
      end

      attr_reader :object, :options

      def initialize(object, options)
        @object = object
        @options = options
      end

      def convert
        object
      end

      def metadata
        {}
      end

      # We default the nested key to be just response for the moment.
      # This will be changed to something else to make it compatible with Ember
      # and the like before the release of 2.0
      # TODO: Finish this off.
      def response_key
        options.fetch :root, 'response'
      end

    end
  end
end