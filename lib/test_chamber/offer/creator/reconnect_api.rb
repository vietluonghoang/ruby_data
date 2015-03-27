module TestChamber::Creator
  class Reconnect
    module Api
      # A Reconnect offer isn't technically related to an engagement offer but the logic for creating them
      # via the API is identical so we'll use that. If they ever differ we should pull the implementation
      # of payload back into this module
      include TestChamber::Creator::Engagement::Api
      
      def create_api_endpoint
        '/api/client/reconnect_ads'
      end
    end
  end
end
