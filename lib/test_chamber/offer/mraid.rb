module TestChamber
  class Offer
    class Mraid < Offer
      def click_action
        'mraid'
      end

      private

      def offer_params_group
        'generic_offers'
      end

      def offer_params_type
        'generic_offer'
      end
    end
  end
end
