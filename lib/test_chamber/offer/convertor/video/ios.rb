module TestChamber::Convertor
  module Video
    module IOS

      # @TODO: Standardize the return code for these because this is a really bad method.
      # Currently, this will either return true or raise an error; it should probably return a useful piece of info for
      # the convert! method.
      def do_conversion!(*args)
        page.driver.appium_driver.within_context('NATIVE_APP') do
          # wait for the video duration plus a buffer
          found_end_card = Util.wait_for(@video_duration + 20, 1) do
            # This uses a special finder that checks tons of things. We could be more specific but this works.
            success_node = page.driver.appium_driver.find("You earned")
            success_node.displayed?
          end
          # this is swallowed by within_context but leaving as living documentation of what we intended for a cleanup.
          found_end_card
        end
      end

      def close_offer!
        page.driver.appium_driver.within_context('NATIVE_APP') do
          page.driver.appium_driver.find("TJCclose button").click

          # The offer doesn't know anything about the offerwall, so we can't use Offerwall#displayed?
          spinner = page.find(:name, "Loading...")
          Util.wait_for(30, 1) do
            !spinner.visible?
          end
        end
      end

      def complete!
        end_card.click!
      end

      def end_card
        TC::Convertor::Video::EndCard.new
      end
    end
  end
end
