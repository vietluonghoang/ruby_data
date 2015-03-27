module TestChamber
  class OfferProperties::VideoUiV1 < OfferProperties
    # @!group Properties

    property! :objective_id, 203

    property :video_path, File.join(TEST_CHAMBER_ROOT, 'assets', 'videotest.mp4')

    property :preview_path, File.join(TEST_CHAMBER_ROOT, 'assets', 'generictest.png')

    property :encoded, false

    property :video_complete_url, NoDefaultValue

    property :tracking_offer, NoDefaultValue

    property :compound_template_url, NoDefaultValue
  end
end
