module TestChamber
  class PartnerProperties < Properties
    #! @group Properties

    property :company_name, -> { "automation-#{SecureRandom.hex(6)}" }

    property :id
    property :reseller_id
    property :discount_all_offer_types
    property :rev_share
    property :max_deduction_percentage
    property :offer_discount
    property :offer_discount_expiration
  end
end
