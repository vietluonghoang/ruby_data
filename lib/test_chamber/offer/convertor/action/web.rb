module TestChamber::Convertor
  module Action
    module Web

      include TestChamber::Convertor::Web

      def convert_with_rest!(publisher_app, params={})
        # Need to get the app for this offer, then run a connect where this offer id
        # is the app id
        # clear as mud

        action_offer = TestChamber::Models::ActionOffer.find(self.id)
        app = TestChamber::App.new(:id => action_offer.item_id)
        app.open_app
      end
    end
  end
end
