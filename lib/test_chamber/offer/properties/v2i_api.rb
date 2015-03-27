module TestChamber
  class OfferProperties::V2IApi < OfferProperties
    # @!group Properties

    property! :objective_id, 201

    property :video_path, File.join(TEST_CHAMBER_ROOT, 'assets', 'videotest.mp4')

    property :encoded, false

    property :video_complete_url, NoDefaultValue

    property :tracking_offer, NoDefaultValue
  end
end
