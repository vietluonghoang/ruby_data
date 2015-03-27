##
# TCR-ADPROD-1359: Verify that successive offer Conversions work
#
# 1. Open Offer wall
# 2. Convert an Offer, and click close button at endcard
# 3. Convert another Offer
# 4. Close Offerwall and return to Game
#
# Expectations:
#   1. Should be able to complete steps without errors.
##

require 'spec_helper'

describe "TCR-ADPROD-1359", :regression do
  context "Convert video offer then close the end card" do

    offers = 2.times.map { TC::Offer::Video.new({:video_path => './assets/sample_mpeg4.mp4'}).id }
    app = TC::App.new

    it 'should not have any problem', :appium do
      TC::OptSOA.set_top_offers(offers, device_id: :all)
      offerwall = app.offerwall
      offer = offerwall.click_offer(offers[0])
      offer.convert!
      offer.close_offer!

      case Capybara.current_driver
        when :android
          expect(offerwall).to_not be_displayed?
        when :ios
          expect(offerwall).to be_displayed?
      end

      # Offers need to be parsed again in order to be able to click on the selected offer.
      offerwall = app.offerwall unless offerwall.displayed?

      another_offer = offerwall.click_offer(offers[1])
      expect(another_offer.convert!).not_to be_nil
      another_offer.close_offer!

      # Will be on offerwall for iOS.
      offerwall.close_offerwall if offerwall.displayed?
      expect(offerwall).to_not be_displayed
    end
  end
end
