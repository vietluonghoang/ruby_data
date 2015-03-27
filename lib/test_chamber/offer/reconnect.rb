module TestChamber
  class Offer
    class Reconnect < Offer
      include TestChamber::Offer::StoreIdEnabler

      validates_presence_of :item_id

      def initialize(options={})
        super(options.merge(validate: false))
        @item_id ||= TestChamber::Models::Offer.find(id).item_id
        populate_store_id

        validate = options.fetch(:validate) { true }
        if validate && invalid?
          raise "Invalid Offer, errors: #{collect_errors}"
        end
      end

      def click_action
        'action'
      end
    end
  end
end
