module TestChamber::Convertor
  module Install
    module Web

      include TestChamber::Convertor::Web

      # The app that this offer is about sends a connect call like it was opened on a device
      def convert_with_rest!(publisher_app, params={})
        # Create the app object with the item id of the offer, which is what will point to the app that this install offer wants you to install.
        # Install offers that aren't the primary offer for an app will not have their id and their app's id match, but the offer's item_id will
        # always be the app that this offer is for.
        raise "item_id is nil so we don't know which app we are converting. This is a bug in test_chamber" unless item_id
        advertiser_app = TestChamber::App.new(id: item_id)
        advertiser_app.open_app
      end
    end
  end
end
