module TestChamber
  class OfferProperties::GenericUiV1 < OfferProperties
    # @!group Properties

    property! :name, -> (s) { "#{s.title} name" }

    property! :details, -> (s) { "#{s.title} details" }

    property! :bid, 0.50

    property  :offer_url, 'http://www.google.com'

    property! :edit_with, :ui_v1

    property! :allow_on_offerwall, true

    property  :category, 'CPA'

    property! :objective_id, 401

    property! :multi_complete, false
  end
end
