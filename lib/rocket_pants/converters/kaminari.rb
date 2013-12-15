module RocketPants
  module Converters
    class Kaminari < Paginated

      def self.converts?(object, options)
        object.respond_to?(:num_pages) && object.respond_to?(:current_page)
      end

      def pagination
        current, total, per_page = collection.current_page, collection.num_pages, collection.limit_value
        {
          current:  current,
          previous: (current > 1 ? (current - 1) : nil),
          next:     (current == total ? nil : (current + 1)),
          per_page: per_page,
          pages:    total,
          count:    collection.total_count
        }
      end

    end
  end
end