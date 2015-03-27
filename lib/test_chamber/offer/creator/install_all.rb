module TestChamber::Creator
  class Install
    # For now this module does all creation for Install offers. Because we are only supporting the primary install
    # offer for an app we never have to actually create an install offer, we just create the app and use that
    # id. So for now this is not used except for consistency where TestChamber::Offer::Thing::API is the preferred
    # way to create an offer. The methods impls are left here since when we do support creating other
    # install offers this is how it works
    module All
      include TestChamber::Offer::StoreIdEnabler
      # Because an install offer is created with every app as the app's Primary Offer we don't have to
      # actually create an install offer. If we are passed in an item_id or 'app' then our offer id is just the primary offer
      # for that app. If we aren't then we create a new app and our id is the offer for that app we just created
      def create!
        # item_id is the id of the app associated with an install offer. If the offer is the primary offer for the
        # app the id is the same. Currently we only support the primary install offer.
        if [app, app_id, item_id].compact.size > 1
          raise "You passed in more than one of app, app_id, and item_id_id for this install offer. They are all equivalent ways to specify the app for this offer. Pick one."
        end

        if app
          self.item_id = app.id
        elsif app_id
          self.item_id = app_id
        end

        unless item_id
          app = TestChamber::App.new :partner_id => partner_id
          self.item_id = app.id
        end
        self.device_types = [TestChamber::Models::App.find(item_id).platform].to_set

        self.id = item_id

        populate_store_id
        # sets things like bid etc which aren't set already because the offer
        # was created with the app
        enable
      end

    end
  end
end
