module TestChamber
  class Offer
    # Install (pay per install, or PPI) offers are created automatically when an App is created.
    # If an app_id is not provided we need to create a new app to create a new PPI Offer.
    #
    # Passing in 'app', 'app_id', or 'item_id' are all equivalent ways of specifying the app for this install offer.
    #
    # PPI Offers have a minimum bid of $0.10.
    #
    # NOTE: right now we only support install ads that are the primary offer for their app.
    # If you need a different type of install offer let the tools team know
    class Install < Offer
      clear_validators!
      validates_presence_of :id, :item_id, :partner_id

      def initialize(options={})
        options[:creator_module] ||= TestChamber::Creator::Install::All

        # Don't validate in the parent initialize as @item_id is assigned after
        # the call to super.  Validation is done after @item_id assignment in
        # this method.
        super(options.merge(validate: false))

        # the item_id for an install offer is the app that the offer is for.
        self.item_id ||= TestChamber::Models::Offer.find(id).item_id
        validate = options.fetch(:validate) { true }
        if validate && self.invalid?
          raise "Invalid Offer, errors: \n #{collect_errors}"
        end
      end

      # With install offers, the part of the click key that specifies the offer
      # actually returns the id of the app that the install offer is for. This is to
      # prevent someone from taking multiple offers for installing the same app if
      # there happen to be multiple offers for that app. So the click key is only
      # unique for device.app
      def click_key_offer_part
        item_id
      end

      # JSON returned by the API about the advertiser app that this install offer is for
      def advertiser_app_info
        return advertiser_app_info if advertiser_app_info

        raise "item_id isn't set yet. This is a bug in test_chamber" unless item_id
        app_api_response = authenticated_request(:post, "/api/client/apps/#{item_id}", payload: payload)
        self.advertiser_app_info = JSON.parse(app_api_response[:body])["result"].first[1]
      end

      # Install offers can only be targeted to the OS that the app runs on
      def target_devices(devices = %w{android iphone ipad itouch windows})
        raise NotImplementedError, "PPI Offers can only target the OS that the app runs on"
      end

      def click_action
        'install'
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
