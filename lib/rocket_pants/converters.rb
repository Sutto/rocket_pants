module RocketPants
  module Converters

    require 'rocket_pants/converters/base'
    require 'rocket_pants/converters/serializable_object'
    require 'rocket_pants/converters/ams'
    require 'rocket_pants/converters/collection'
    require 'rocket_pants/converters/paginated'
    require 'rocket_pants/converters/kaminari'
    require 'rocket_pants/converters/will_paginate'

    PAGINATED  = [WillPaginate, Kaminari]
    COLLECTION = [*PAGINATED, Collection]
    INDIVIDUAL = [AMS, SerializableObject, Base]

    ALL = [*COLLECTION, *INDIVIDUAL]

    def self.fetch(object, options)
      converter = ALL.detect { |k| k.converts? object, options }
      raise "No Converter found for #{object.inspect}" unless converter
      converter.new object, options
    end

    def self.serialize_single(object, options)
      converter = INDIVIDUAL.detect { |k| k.converts? object, options }
      raise "No Converter found for #{object.inspect}" unless converter
      converter.new(object, options).convert
    end

  end
end