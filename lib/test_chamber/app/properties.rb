module TestChamber
  # TODO we need to audit all of the properties in OfferProperties and pull out App specific properties
  class AppProperties < OfferProperties
    # @!group Properties

    property :currency_name

    property :currency_id

    property :rewarded_currency_ids

    property :source

    property :ignore_cache
  end
end
