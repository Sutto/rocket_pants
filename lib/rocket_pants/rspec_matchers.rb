module RocketPants
  module RSpecMatchers
    extend RSpec::Matchers::DSL

    def self.normalised_error(e)
      if e.is_a?(String) || e.is_a?(Symbol)
        Errors[e]
      else
        e
      end
    end

    def self.normalise_urls(object)
      if object.is_a?(Array)
        object.each { |o| o['url'] = nil }
      elsif object.is_a?(Hash) || object.is_a?(APISmith::Smash)
        object['url'] = nil
      end
      object
    end

    # Converts it to JSON and back again.
    def self.normalise_as_json(object, options = {})
      if object.is_a?(Array)
        object.map { |o| normalise_as_json o, options.reverse_merge(:compact => true) }
      else
        object = object.serializable_hash options if object.respond_to?(:serializable_hash)
        j = ActiveSupport::JSON
        j.decode(j.encode({'object' => object}))['object']
      end
    end

    def self.normalise_response(response)
      normalise_urls normalise_as_json response
    end

    def self.valid_for?(response, allowed, disallowed)
      body = response.decoded_body
      return false if body.blank?
      body = body.to_hash
      return false if body.has_key?("error")
      allowed.all? { |f| body.has_key?(f) } && !disallowed.any? { |f| body.has_key?(f) }
    end

    matcher :_be_api_error do |error_type|

      match do |response|
        error = response.decoded_body.error
        error.present? && (error_type.blank? || RSpecMatchers.normalised_error(error) == error_type)
      end

      failure_message_for_should do |response|
        error = response.decoded_body.error
        if error.blank?
          "expected #{error_type || "any error"} on response, got no error"
        else error_type.present? && (normalised = RSpecMatchers.normalised_error(error)) != error_type
          "expected #{error_type || "any error"} but got #{normalised} instead"
        end
      end

      failure_message_for_should_not do |response|
        error = RSpecMatchers.normalised_error(response.decoded_body.error)
        "expected response to not have an #{error_type || "error"}, but it did (#{error})"
      end

    end

    matcher :be_singular_resource do

      match do |response|
        RSpecMatchers.valid_for? response, %w(), %w(count pagination)
      end

    end

    matcher :be_collection_resource do

      match do |response|
        RSpecMatchers.valid_for? response, %w(count), %w(pagination)
      end

    end

    matcher :be_paginated_resource do

      match do |response|
        RSpecMatchers.valid_for? response, %w(count pagination), %w()
      end

    end

    matcher :have_exposed do |object|
      normalised_response = RSpecMatchers.normalise_response(object)

      match do |response|
        decoded = RSpecMatchers.normalise_urls(response.decoded_body.response)
        normalised_response == decoded
      end

      failure_message_for_should do |response|
        decoded = RSpecMatchers.normalise_urls(response.decoded_body.response)
        "expected api to have exposed #{normalised_response.inspect}, got #{decoded.response} instead"
      end

      failure_message_for_should_not do |response|
        "expected api to not have exposed #{normalised_response.inspect}"
      end

    end

    def be_api_error(error = nil)
      _be_api_error error
    end


  end
end