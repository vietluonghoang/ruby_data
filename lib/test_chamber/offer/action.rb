
module TestChamber
  # PPA (pay per action) offers are created automatically when an App is created.
  # If an app id is not provided we need to create a new app to create a new PPI Offer.
  class Offer
    class Action < Offer
      include TestChamber::Offer::StoreIdEnabler
      validates_presence_of :app_id

      def enable(options = {self_promote_only: false, admin_only: false, featured: false})
        populate_store_id
        super(options)
      end

      def click_action
        'action'
      end

    end
  end
end
