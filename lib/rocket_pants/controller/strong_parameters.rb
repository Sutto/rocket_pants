module RocketPants
  module StrongParameters
    extend ActiveSupport::Concern

    included do
      include ActionController::StrongParameters
      map_error! ActionController::ParameterMissing, RocketPants::BadRequest
      map_error! ActionController::UnpermittedParameters, RocketPants::BadRequest
    end
  end
end
