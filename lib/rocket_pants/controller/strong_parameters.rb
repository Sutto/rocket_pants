module RocketPants
  module StrongParameters
    extend ActiveSupport::Concern

    included do
      if defined? ActionController::StrongParameters
        include ActionController::StrongParameters
        map_error! ActionController::ParameterMissing, RocketPants::BadRequest
        map_error! ActionController::UnpermittedParameters, RocketPants::BadRequest
      end
    end
  end
end
