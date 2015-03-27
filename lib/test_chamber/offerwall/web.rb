module TestChamber
  class Offerwall
    module Web

      extend Gem::Deprecate

      # Navigate to offerwall.
      # @return [void]
      # @see (Offerwall#visit_offerwall)
      def visit_offerwall
        visit offerwall_url
      end

      # "Click" the offer in the offerwall with the given id, using a rest
      # request for better error handling.
      # @param (see Offerwall#click_offer)
      # @return (see Offerwall#click_offer)
      # @see Offerwall#click_offer
      def click_offer(id)
        # @todo: This should raise if the offer is not on the wall.
        offer = offers.find { |o| o.id == id }
        offer.click_with_rest!(@app)
        offer
      end

      # "Click" the offer in the offerwall with the given index, using a rest
      # request for better error handling
      # @param (see Offerwall#click_offer_by_index)
      # @return (see Offerwall#click_offer_by_index)
      # @see Offerwall#click_offer_by_index
      def click_offer_by_index(idx)
        # @todo: This should raise if the offer is not on the wall.
        click_url = offer_map.values[idx][:click_url]
        rest_request(:get, click_url, payload: {}, format: :html)
        offers.find { |offer| offer.id == id }
        offer
      end

      # Convert the offer in the offerwall with the given id
      # @param (see Offerwall#convert_offer)
      # @return (see Offerwall#convert_offer)
      # @see Offerwall#convert_offer
      # @deprecated Please use Offer#convert! instead.
      def convert_offer(id)
        offer = offers.find { |o| o.id == id }
        offer.complete_conversion(@app)
      end
      deprecate :convert_offer, :none, 2015, 03

      # Convert the offer in the offerwall with the given index
      # @param (see Offerwall#convert_offer_by_index)
      # @return (see Offerwall#convert_offer_by_index)
      # @see Offerwall#convert_offer_by_index
      # @deprecated Please use Offer#convert! instead.
      def convert_offer_by_index(idx)
        offers[idx].complete_conversion(@app)
      end
      deprecate :convert_offer_by_index, :none, 2015, 03

      private

      # Params used to construct offerwall URL. Not used in cases where we can
      # navigate to the offerwall in-app.
      # @return [Hash] Query params merged from current device used to build
      #   offerwall url.
      def offerwall_params
        TestChamber.current_device.query_params.merge({
          lad: "0",
          ad_tracking_enabled: "true",
          app_id: @app.id,
          app_version: @app.version,
          bridge_version: @app.bridge_version,
          exp: "ow_coffee",
          currency_selector: "0",
          reqp: "1",
          reqr: "nzcdYaEvLaE5pv5jLab="
        })
      end

      # Constructs the offerwall url from params.
      # @return [void]
      # @see Offerwall#offerwall_params
      def offerwall_url
        "#{TestChamber.target_url}/get_offers/webpage?#{offerwall_params.to_query}"
      end
    end
  end
end
