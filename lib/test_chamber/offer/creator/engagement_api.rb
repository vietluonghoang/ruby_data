module TestChamber::Creator
  class Engagement
    module Api
      include TestChamber::Offer::ApiBehavior

      def create_payload
        payload = init_payload
        # we get a 422 if this is set to true with the error:
        # See the StoreIdEnabler module documentation for why this is
        payload[:tapjoy_enabled] = false
        payload
      end
      
      def create_api_endpoint
        '/api/client/pay_per_engagement_ads'
      end
    end
  end
end
