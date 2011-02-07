module RocketPants
  module UrlFor
    
    def url_options
      options = super
      options = options.merge(:version => version) if version.present?
      options
    end
    
  end
end