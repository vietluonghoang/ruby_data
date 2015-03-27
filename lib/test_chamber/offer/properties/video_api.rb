module TestChamber
  class OfferProperties::VideoApi < OfferProperties
    # @!group Properties

    property! :objective_id, 203

    property :video_path, File.join(TEST_CHAMBER_ROOT, 'assets', 'videotest.mp4')

    property :encoded, false

    property :video_complete_url, NoDefaultValue

    property :tracking_offer, NoDefaultValue
  end
end
