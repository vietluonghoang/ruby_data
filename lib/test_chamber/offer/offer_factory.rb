module TestChamber
  # Knows how to take an arbitrary offer_id and create the correct type of offer
  # object for it.
  class OfferFactory

    # Determines the type of offer and returns an instance of the correct
    # subclass of TestChamber::Offer.
    #
    # Returns nil if the id does not specify an existing offer
    def self.make_offer(id, opts={})
      begin
        raw_offer = TestChamber::Models::Offer.find(id)
        type = raw_offer.item_type
        clazz = offer_class(type)
        raise "No TestChamber offer class for type #{type}" unless clazz
        if type == 'ActionOffer'
          if raw_offer.app
            opts[:app_id] = raw_offer.app.id
          elsif raw_offer.item_id
            item_model = TestChamber::Models::ActionOffer.find(raw_offer.item_id)
            opts[:app_id] = item_model.app_id
          end
        end
        clazz.new(opts.merge(id: id, item_type: type))
      rescue ActiveRecord::RecordNotFound
        puts "Could not make an Offer object from offer found on offerwall because it was not found in the DB: #{id}"
      end
    end

    # return the Offer subclass which maps to the offer_type argument.
    # offer_type is the value of "item_type" on the Offer object in the database
    def self.offer_class(offer_type)
      case offer_type
      when "VideoOffer"
        TestChamber::Offer::Video
      when "GenericOffer"
        TestChamber::Offer::Generic
      when "MraidOffer"
        TestChamber::Offer::Mraid
      when "App"
        TestChamber::Offer::Install
      when "ActionOffer"
        TestChamber::Offer::Action
      when "SurveyOffer"
        TestChamber::Offer::Survey
      else
        puts "**********  Unknown offer type #{offer_type}. We don't know how to make those yet."
      end
      #Need to add Deeplink and Reseller
    end
  end
end
