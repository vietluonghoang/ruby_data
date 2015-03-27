module TestChamber::Creator
  class Action 
    module Api
      include TestChamber::Offer::ApiBehavior

      def create_payload
        payload = init_payload
        payload[:title] ||= "TestChamber Video Offer #{Util.name_datestamp}"
        payload[:marquee_preview_image] = upload_marquee_preview_image_via_api
        payload[:adicon_name] = upload_adicon_via_api
        payload[:background_name] = upload_background_via_api
        
        payload[:video_offer] = {
          :video_url => video_url,
          :name => name
        }

        payload[:'video_buttons[]'] = [v2i_video_button] if tracking_offer
        payload
      end
   
      def create_api_endpoint
        '/api/client/video_ads'
      end

    end
  end
end
