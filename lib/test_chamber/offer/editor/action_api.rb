module TestChamber::Editor
  class Action
    module Api
      include TestChamber::Offer::ApiBehavior

      # Attach additional fields including marquee_preview_image, icon, background and video_offer
      # will only add non nil fields from properties
      # @param properties [TestChamber::Properties]
      def edit_payload(properties)
        payload = init_payload(properties)

        if properties.marquee_preview_image_path
          payload[:marquee_preview_image] = upload_marquee_preview_image_via_api
        end
        if properties.icon_path
          payload[:adicon_name] = upload_adicon_via_api
        end
        if properties.background_path
          payload[:background_name] = upload_background_via_api
        end

        if properties.video_url
          payload[:video_offer] = {
              :video_url => properties.video_url,
              :name => properties.name || @name
          }
        end

        payload[:'video_buttons[]'] = [properties.v2i_video_button || v2i_video_button] if properties.tracking_offer
        payload
      end

      # Update endpoint is the same as create
      def update_api_endpoint
        create_api_endpoint
      end

    end
  end
end
