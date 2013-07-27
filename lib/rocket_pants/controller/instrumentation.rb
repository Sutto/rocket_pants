require 'action_controller/log_subscriber'
require 'abstract_controller/logger'

module RocketPants
  module Instrumentation
    extend  ActiveSupport::Concern
    include AbstractController::Logger

    def process_action(action, *args)
      raw_payload = {
        :controller => self.class.name,
        :action     => self.action_name,
        :params     => request.filtered_parameters,
        :formats    => [:json],
        :method     => request.method,
        :path       => (request.fullpath rescue "unknown")
      }

      ActiveSupport::Notifications.instrument("start_processing.rocket_pants", raw_payload.dup)

      ActiveSupport::Notifications.instrument("process_action.rocket_pants", raw_payload) do |payload|
        result = super
        payload[:status] = response.status
        append_info_to_payload payload
        result
      end
    end

    private

    def append_info_to_payload(payload) #:nodoc:
      # Append any custom information here.
    end

  end
  ActionController::LogSubscriber.attach_to :rocket_pants
end