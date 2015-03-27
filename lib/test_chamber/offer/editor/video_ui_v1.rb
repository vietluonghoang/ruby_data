module TestChamber::Editor
  class Video
    module UiV1
      include TestChamber::UiBehavior

      # Extend default UI behavior to attach video file if it exist in properties
      # @param [TestChamber::Properties] properties
      def edit!(properties)
        super(properties)
        visit video_edit_url
        if properties.video_path
          attach_file('video_offer_input_video_file', properties.video_path)
        end
        click_button('video_offer_submit')
      end

      # Endpoint that contains the video upload field and other video specific
      # edit fields.
      def video_edit_url
        "#{TestChamber.target_url}/dashboard/tools/video_offers/#{id}/edit"
      end

    end
  end
end
