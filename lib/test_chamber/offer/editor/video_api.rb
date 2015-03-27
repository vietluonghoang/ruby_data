module TestChamber::Editor
  class Video
    module Api
      include TestChamber::Offer::ApiBehavior

      # Edit the video offer using the payload from #edit_payload.  Updates the
      # request format to :multipart if the payload includes a video file
      # @param [TestChamber::Properties] properties
      def edit!(properties)
        payload = edit_payload(properties)
        # use multipart format if a video file is included
        format = :multipart unless payload[:video_offer].nil?
        payload = edit_payload(properties)
        payload[:bid] = (payload[:bid] * 100) unless payload[:bid].nil?
        @edit_api_body = update_with_api(payload, format)
      end

      # Several additions to the default payload including marquee_preview_image, icon,
      # background and video file
      # @param [TestChamber::Properties] properties
      def edit_payload(properties)
        init_payload(properties).tap do |payload|

          if properties.marquee_preview_image_path
            payload[:marquee_preview_image] = upload_marquee_preview_image_via_api
          end
          payload[:adicon_name] = upload_adicon_via_api if properties.icon_path
          payload[:background_name] = upload_background_via_api if properties.background_path

          if properties.video_path
            video_file = File.new(video_path, 'rb')
            payload[:video_offer] = {
              :video_url => video_url,
              :name => name,
              :input_video_file => Faraday::UploadIO.new(video_file, "video/mp4")
            }
          end

          payload[:'video_buttons'] = [v2i_video_button] if properties.tracking_offer
        end
      end

      # Update endpoint is the same as create
      def update_api_endpoint
        create_api_endpoint
      end

      def format
        :json
      end

    end
  end
end
