module TestChamber::Convertor
  module Video
    module Android

      def do_conversion!(*args)
        # wait for the duration of the video plus a buffer
        success = Util.wait_for(@video_duration + 20, 1) do
          page.first(:id, "cta").visible?
        end
        success
      end

      def close_offer!
        page.driver.appium_driver.within_context('NATIVE_APP') do
          # @TODO: There needs to be better logic for this wait but for now this is fine.
          Util.wait_for(@video_duration + 20, 1) do
            page.first(:class, "android.widget.ImageButton").visible?
          end
          page.find(:class, "android.widget.ImageButton").click
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
