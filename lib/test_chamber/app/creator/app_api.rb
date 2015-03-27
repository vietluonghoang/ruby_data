module TestChamber::Creator
  class App
    module Api
      include TestChamber::ApiBehavior

      def create!
        create_with_api
      end

      def create_non_rewarded_currency
        nr_currency_payload = {
          app_id: id,
          terms_of_service: '1'
        }
        
        response = authenticated_request(:post, "/dashboard/apps/#{id}/non_rewarded", payload: nr_currency_payload)
        JSON.parse(response[:body])["result"]["currency"]["id"]
      end

      def add_to_apps_network
        raise "This method requires apps_network_id to be set" unless apps_network_id
        apps_network_payload = {
          app_ids: id,
        }
        authenticated_request(:post, "/dashboard/tools/apps_network_association/#{apps_network_id}/create", payload: apps_network_payload)
      end

      def create_currency(currency_name = 'Coins')
        currency_payload = {
          currency: {
            name: currency_name
          },
          app_id: id,
          name:   currency_name,
        }
        response = authenticated_request(:post,"/api/client/apps/#{id}/currencies", payload: currency_payload)
        currency_id = JSON.parse(response[:body])["result"]["currency"]["id"]
        unless TestChamber::UUID.uuid?(currency_id)
          raise "Failed to create virtual currency. URL was '#{current_url}'."
        end
        currency_id
      end

      def payload
        {
          app: {
            platform: platform.downcase,
            name:     name
          },
          state: state,
          platform: platform,
          name: name,
          partner_id: partner_id
        }
      end

      def api_endpoint
        "/api/client/partners/#{partner_id}/apps"
      end
    end
  end
end
