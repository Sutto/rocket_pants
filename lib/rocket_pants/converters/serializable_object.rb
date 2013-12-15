module RocketPants
  module Converters
    class SerializableObject < Base

      METHODS = [:serializable_hash, :serializable_object]

      def self.converts?(object, options)
        METHODS.any? { |m| object.respond_to?(m) }
      end

      attr_reader :object, :options

      def convert
        method = METHODS.detect { |m| object.respond_to?(m) }
        object.send method, options
      end

    end
  end
end