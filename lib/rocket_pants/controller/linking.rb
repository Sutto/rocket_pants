module RocketPants
  module Linking

    # Generates a Link: header with the specified rel, uri and attributes.
    # @param [String, Symbol] rel the relation of the given link
    # @param [String] uri the full uri to the specified link resource
    # @param [Hash] attributes any other attributes for the link
    def link(rel, uri, attributes = {})
      headers['Link'] ||= []
      attributes = {:rel => rel}.merge(attributes)
      link = "<#{uri}>"
      attributes.each_pair { |k, v| link << "; #{k}=\"#{v}\"" }
      headers['Link'] << link
    end

    # Lets you add a series of links for the current resource.
    # @param [Hash{Symbol => String}] links a hash of links. Those with nil as the value are skipped.
    def links(links = {})
      links.each_pair do |rel, uri|
        link rel, uri if uri
      end
    end

    # Hook method - Implement this to link to the current resource and we'll automatically add header links.
    def page_url(page)
      nil
    end

    def expose_metadata(metadata)
      super.tap do |meta|
        if RocketPants.header_metadata? && (pagination = meta[:pagination])
          links :next  => (pagination[:next] && page_url(pagination[:next])),
                :prev  => (pagination[:previous] && page_url(pagination[:previous])),                
                :last  => (pagination[:pages] && page_url(pagination[:pages])),
                :first => page_url(1)
        end
      end
    end

  end
end