module TestChamber
  class OfferProperties::MraidUiV1 < OfferProperties
    # @!group Properties

    property! :bid, 0.01

    property! :edit_with, :ui_v1

    property! :objective_id, 501

    property  :icon, File.join(TEST_CHAMBER_ROOT, 'assets', 'mraidtest.png')

    property  :mraid_phone_txt, File.read(File.join(TEST_CHAMBER_ROOT, 'assets', 'mraidphonetest.txt'))
  end
end
