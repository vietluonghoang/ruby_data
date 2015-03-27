module TestChamber::Editor
  class Reconnect
    module Api

      # Only uses the default payload at this time
      # @param [TestChamber::Properties] properties
      def edit_payload(properties)
        init_payload(properties)
      end

      # Update endpoint is the same as create
      def update_api_endpoint
        create_api_endpoint
      end

    end
  end
end
