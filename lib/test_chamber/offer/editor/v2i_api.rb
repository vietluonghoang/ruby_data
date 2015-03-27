module TestChamber::Editor
  class V2I
    module Api

      # Only uses the default payload at this time
      # @param [TestChamber::Properties] properties
      def edit_payload(properties)
        init_payload(properties)
      end

      # Update endpoint is the same as create
      def update_api_endpoint
        '/api/client/video_ads'
      end

      def format
        :json
      end

    end
  end
end
