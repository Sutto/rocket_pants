module RocketPants
  module Converters
    class Collection < Base

      alias collection object

      def self.converts?(object, options)
        object.is_a?(Array) || object.respond_to?(:to_ary)
      end

      def convert
        collection.map { |object| serialize_associated(object, options) }
      end

      def metadata
        super.merge! count: collection.size
      end

      private

      def serialize_associated(associated, options)
        Converters.serialize_single associated, options
      end

    end
  end
end