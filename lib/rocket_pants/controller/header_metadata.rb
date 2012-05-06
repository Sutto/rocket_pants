module RocketPants
  module HeaderMetadata

    # Given a hash of request metadata, will:
    # 1. Write out the headers for the current metadata
    # 2. Return the hash, suitable for merging into the response hash
    # 3. Start a dance party.
    #
    # @param  [Hash{Symbol => Object}] metadata the hash of the request metadata.
    # @return [Hash{Symbol => Object}] the passed in metadata
    def expose_metadata(metadata)
      metadata_headers { build_header_hash(metadata) }
      super # Call any other versions of the method.
    end


    # Given a block which returns a Hash, will call and merge the block iff header metadata
    # is enabled. This is to avoid the overhead of generating headers on every request when
    # it's disabled.
    def metadata_headers(&blk)
      headers.merge! blk.call if RocketPants.header_metadata?
    end

    def build_header_hash(options, hash = {}, prefix = 'X-Api')
      options.each_pair do |k, v|
        current = "#{prefix}-#{k.to_s.titleize.tr(" ", "-")}"
        if v.is_a?(Hash)
          build_header_hash v, hash, current
        else
          value = Array(v).join(", ")
          hash[current] = value if value.present?
        end
      end
      hash
    end

  end
end
