module RocketPants
  module Converters
    class WillPaginate < Paginated

      def self.converts?(object, options)
        object.respond_to?(:total_entries)
      end

      def pagination
        {
          previous: collection.previous_page.try(:to_i),
          next:     collection.next_page.try(:to_i),
          current:  collection.current_page.try(:to_i),
          per_page: collection.per_page.try(:to_i),
          count:    collection.total_entries.try(:to_i),
          pages:    collection.total_pages.try(:to_i)
        }
      end

    end
  end
end