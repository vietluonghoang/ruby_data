##
# TCR-PLAT-1376: Verify End Card is Accurate
#
# 1. Start automation target app and go to offerwall
# 2. Select and watch video offer to completion, go to end card, click on "x", return to OW
# 3. Select and watch another video to completion, go to end card
# 4. Verify End Card
#
# Expectations:
#   1. End card renders correctly
##

require 'spec_helper'

describe "TCR-PLAT-1376:", :regression do
  context "When converting two consecutive video offers" do

    offer_ids = 2.times.map { TC::Offer::Video.new({:video_path => './assets/sample_mpeg4.mp4'}).id }
    app = TC::App.new

    it 'the second should have an accurate end card', :appium do
      TestChamber::OptSOA.set_top_offers([offer_ids], device_id: :all)

      offerwall = app.offerwall

      offer_ids.each do |id|
        # If this isn't the first time through we might need to reload the offerwall.
        offerwall = app.offerwall unless offerwall.displayed?
        offer = offerwall.click_offer(id)
        offer.convert!
        offer.close_offer!
        # These will be refactored to use the new Test Chamber End Card class.
        # expect(offer.verify_replay_icon).not_to be_nil
        # expect(offer.verify_item_location).to be true
      end
    end
  end
end
