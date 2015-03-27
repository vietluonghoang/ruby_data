module TestChamber
  class Offer
    class Generic < Offer

      GENERIC_CLICK_MACROS = TestChamber::Offer::CLICK_MACROS.merge({
        generic_invite: "TAPJOY_GENERIC_INVITE",
        tjm_eid: "TJM_EID",
        data: "DATA"
      })

      def offer_params_group
        'generic_offers'
      end

      def offer_params_type
        'generic_offer'
      end

      def click_action
        'generic'
      end

      def enable(options = {})
        if options[:multi_complete].nil? && instructions.nil?
          options[:multi_complete] = false
        end
        super(options)
      end

      private

      def click_key
        Digest::MD5.hexdigest(super)
      end
    end
  end
end
