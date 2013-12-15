module RocketPants
  module Converters
    class Paginated < Collection

      def self.converts?(object, options)
        raise NotImplementedError.new("This must be implemented in your specified paginated converter")
      end

      def metadata
        super.tap do |metadata|
          metadata[:pagination] = pagination
        end
      end

      def pagination
        raise NotImplementedError.new("This must be implemented in your specified paginated converter.")
      end

    end
  end
end