# Provides a way of selecting certain field attributes to present in the JSON response
module RocketPants
  module Presenter
    extend ActiveSupport::Concern

    included do
      class_attribute :_presented_attributes
    end

    module ClassMethods
      # Accepts a list of attributes to be presented in the response
      #
      def attr_expose(*args)
        options = args.extract_options!
        self._presented_attributes = (self._presented_attributes || []) + args
      end
    end

    # Override to only show model attributes marked for presentation with attr_presented
    def serializable_hash(options = {})
      options[:only] = (options[:only] || []) | (self.class._presented_attributes || [])
      options[:only] = nil if options[:only].empty?
      super(options)
    end

    ActiveSupport.on_load :active_record do
      ActiveRecord::Base.send :include, RocketPants::Presenter
    end
  end
end
