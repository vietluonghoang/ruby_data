require 'spec_helper'

describe "On a mobile device" do
  context "it creates a video offer in the dashboard", :appium do
    it "loads a mobile offerwall showing an offer" do

      ##
      # 'using_driver' is a built in Capybara method which takes a driver and a
      # block and executes that block using the driver. Very handy. Essentially
      # the same as:
      #
      # Capybara.current_driver = :selenium
      # offer = TestChamber::Offer::Generic.new
      # Capybara.current_driver = :ios
      #
      # The big advantage here being that we don't know what the appium driver
      # is called since it's set at runtime. So rather than save and retrive it,
      # using_driver does it for us.
      #
      # Sweet.
      #
      # If the test is primarily in appium, this pattern makes sense. If not,
      # you can invert the pattern thusly:
      #
      # Capybara.current_driver = :selenium
      # ...selenium things here...
      # Capybara.using_driver :appium do
      #   ...appium things here...
      # end
      ##
      Capybara.using_driver :selenium do
        @offer = TestChamber::Offer::Generic.new
      end

      # @todo: Since this uses :all we need to be very careful. It currently
      # breaks all TIAB since the partner used to create @offer is deleted.
      TestChamber::OptSOA.set_top_offers([@offer.id], device_id: :all)
      offerwall = TestChamber::Offerwall.new(app: 'EasyApp')
      offerwall.click_offer(@offer.id)
    end
  end
end
