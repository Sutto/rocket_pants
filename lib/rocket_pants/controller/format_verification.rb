module RocketPants
  module FormatVerification
    extend ActiveSupport::Concern

    included do
      before_filter :ensure_has_valid_format
    end

    private

    def ensure_has_valid_format
      head 422 unless request.format.json?
    end

  end
end