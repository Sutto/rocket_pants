# Provides a bunch of default active record integration entry points.
module RocketPants
  module ActiveRecordIntegration
    extend ActiveSupport::Concern

    included do
      map_error! ActiveRecord::RecordNotFound, RocketPants::NotFound
      map_error! ActiveRecord::RecordNotUnique, RocketPants::Conflict
      map_error!(ActiveRecord::RecordNotSaved) { RocketPants::InvalidResource.new nil }
      map_error! ActiveRecord::RecordInvalid do |exception|
        RocketPants::InvalidResource.new exception.record.errors
      end
    end

    ActiveSupport.on_load :active_record do
      RocketPants::Base.send :include, RocketPants::ActiveRecordIntegration
    end

  end
end
