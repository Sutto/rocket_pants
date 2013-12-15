module RocketPants
  module Converters
    class AMS < Base

      def self.support?(object, options)
        options[:serializer].present? || object.respond_to?(:active_model_serializer)
      end

      def convert(object, options)
        serializer = serializer_for object, options
        serializer.new(object, options.merge(root: false)).serializable_hash
      end

      private

      def serializer_for(object, options)
        options[:serializer] ||  object.active_model_serializer
      end

    end
  end
end