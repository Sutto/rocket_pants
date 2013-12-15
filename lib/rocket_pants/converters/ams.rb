module RocketPants
  module Converters
    class AMS < Base

      # TODO: Let the user specify we use the root key from the serializer, if possible.

      def self.converts?(object, options)
        options[:serializer].present? || (object.respond_to?(:active_model_serializer) && object.active_model_serializer)
      end

      def convert
        serializer_klass.new(object, options.merge(root: false)).serializable_hash
      end

      private

      def serializer_klass
        # TODO: we need to support using the AMS build in stuff.
        options[:serializer] ||  object.active_model_serializer
      end

    end
  end
end