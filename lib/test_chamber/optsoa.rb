module TestChamber
  # Wrapper class to handle interactions with FakeOptSOA
  # This probably won't work on any TIAB that doesn't have it enabled
  # See also: https://github.com/Tapjoy/fakeoptsoa
  class OptSOA
    class << self
      # Set Response using an explicit device_id, defaults to current device
      def set_response(resp = {}, device_id: TestChamber.current_device.normalized_id)
        RestClient.post("#{url_for_device_id(device_id)}/response", response: resp.to_json)
      end

      # Set top offers using an explicit device_id, defaults to current device
      def set_top_offers(offer_ids, device_id: TestChamber.current_device.normalized_id)
        RestClient.post("#{url_for_device_id(device_id)}/top", offer_ids: offer_ids)
      end

      # Set only offers response using an explicit device_id, defaults to current device
      def set_only_offers(offer_ids, device_id: TestChamber.current_device.normalized_id)
        RestClient.post("#{url_for_device_id(device_id)}/only", offer_ids: offer_ids)
      end

      # Get response for current device
      def response
        response_for_device(TestChamber.current_device.normalized_id)
      end

      # Get response for the provided device id, will return response/offers registered in
      # 'default' methods (e.g. default_response=) if the device_id has not been registered
      def response_for_device(device_id)
        raw = RestClient.get("#{url_for_device_id(device_id, method: :get)}")
        JSON.parse(raw) if raw.is_a? String
      end

      # Build the fakeoptsoa url for the provided device and method
      # If no device_id is provided the URL will be built for any device
      def url_for_device_id(device_id, method: :post)
        url = "#{TestChamber.target_url}:4567"

        url += "/devices/#{device_id}" if method == :post
        url += "?udid=#{device_id}" if method == :get
        url
      end
    end
  end
end
