##
# TCR-PLAT-1167: Offerwall not showing after conversion
#
# 1. Open Offer wall
# 2. Complete any Video offer from the offerwall
# 3. Click close on the End card of the video
#
# Expectations:
#   1. On iOS, Offerwall should be displayed after watching a video and clicking close.
#   2. On Android, the App should be displayed after watching a video and clicking close.
#
# @TODO: Is this incidental behavior due to how the SampleApp is written, or is this codified in the SDK?
##

require 'spec_helper'

describe 'TCR-PLAT-1167:', :regression do
  context 'After closing the encard', :appium do
    offer = TC::Offer::Video.new({:video_path => './assets/sample_mpeg4.mp4'})
    app = TC::App.new

    it 'should reopen offerwall' do
      TC::OptSOA.set_top_offers([offer.id], device_id: :all)
      offerwall = app.offerwall

      offer = offerwall.click_offer(offer.id)
      offer.convert!
      offer.close_offer!

      # @TODO: How do we handle android and ios only test cases? Probably tagging and filtering.
      case Capybara.current_driver
        when :android
          expect(offerwall).to_not be_displayed
          # The android test case needs to actually confirm that it's on the app, not just that we can't see the offerwall.
          # So, let's try making a new one. If this fails, we know we couldn't see the Offerwall button.
          app.offerwall
        when :ios
          expect(offerwall).to be_displayed
      end
    end
  end
end
