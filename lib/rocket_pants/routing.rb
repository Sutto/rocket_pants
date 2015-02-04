module RocketPants
  module Routing

    # Scopes a set of given api routes, allowing for option versions.
    # @param [Hash] options options to pass through to the route e.g. `:module`.
    # @option options [Array<Integer>, Integer] :versions the versions to support
    # @option options [Array<Integer>, Integer] :version the single version to support
    # @raise [ArgumentError] raised when the version isn't provided.
    def rocket_pants(options = {}, &blk)
      versions = extract_rocket_pants_versions options

      defaults = {:format => 'json'}

      if (optional_prefix = options.delete(:allow_prefix))
        versions.map! { |v| "#{optional_prefix}?#{v}" }
        defaults[:rp_prefix] = {:text => optional_prefix.to_s, :required => false}
      elsif (required_prefix = options.delete(:require_prefix))
        versions.map! { |v| "#{required_prefix}#{v}" }
        defaults[:rp_prefix] = {:text => required_prefix.to_s, :required => true}
      end
      versions_regexp = /(#{versions.uniq.join("|")})/
      raise ArgumentError, 'please provide at least one version' if versions.empty?
      options = options.deep_merge({
        :constraints => {:version => versions_regexp},
        :path        => ':version',
        :defaults    => defaults
      })
      scope options, &blk
    end
    alias api rocket_pants

    private

    def extract_rocket_pants_versions(options)
      versions = (Array(options.delete(:versions)) + Array(options.delete(:version))).flatten.map(&:to_s)
      versions.each do |version|
        raise ArgumentError, "Got invalid version: '#{version}'" unless version =~ /\A\d+\Z/
      end
      versions
    end

  end
end
