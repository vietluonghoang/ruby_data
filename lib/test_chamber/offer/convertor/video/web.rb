module TestChamber::Convertor
  module Video
    module Web

      include TestChamber::Convertor::Web

      alias_method :convert_offer, :convert_with_rest!

      def convert_with_rest!(publisher_app, params={})
        unless video_complete_url
          raise "video_complete_url has not been set yet. You have to call #complete_click before initiating a conversion"
        end

        # Call convert_with_rest! from the video offer.
        convert_offer(publisher_app, params=params)
        visit video_complete_url
        # TODO valdiate end card
      end
    end
  end
end
