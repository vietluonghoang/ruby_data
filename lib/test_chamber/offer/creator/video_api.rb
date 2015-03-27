module TestChamber::Creator
  class Video
    module Api
      include TestChamber::Offer::ApiBehavior

      def create_payload
        payload = init_payload
        
        payload[:marquee_preview_image] = upload_marquee_preview_image_via_api
        payload[:title] ||= "TestChamber Video Offer #{Util.name_datestamp}"
        payload[:adicon_name] = upload_adicon_via_api
        payload[:background_name] = upload_background_via_api

        video_file = File.new(video_path, 'rb')
        payload[:video_offer] = {
          :video_url => video_url,
          :name => name,
          :input_video_file => Faraday::UploadIO.new(video_file, "video/mp4") 
        }

        payload[:'video_buttons'] = [v2i_video_button] if tracking_offer
        payload
      end

      # A tracking offer is the install app offer part of a V2I (video to install) offer set.
      # The way V2I works is that the video offer is created with a video button configured with
      # an install tracking offer. The end card of the video shows the button which takes you to
      # install the app being previewed. It is possible to convert just the video or the video
      # and the install part and reporting in TJS has been changed to reflect that. 
      def v2i_video_button
        {
          enabled: true,
          name: "VB #{summary}",
          ordinal: 1,
          tracking_source_offer_id: tracking_offer,
          summary: "VB #{summary}"
        }
      end
      
      def create_api_endpoint
        '/api/client/video_ads'
      end

      def format
        :multipart
      end

    end
  end
end
