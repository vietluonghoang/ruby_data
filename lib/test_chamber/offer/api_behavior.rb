module TestChamber
  class Offer

    # Logic shared across all offer types created and edited with the API
    module ApiBehavior
      include TestChamber::ApiBehavior
      attr_reader :create_api_response, :create_api_body

      # Create method for API creation modules.  Method retrieves payload from #create_payload, updates bid,
      # min_bid_override and name fields before passing to #create_with_api method
      def create!
        # TODO API uses bid in cents not dollars. We should fix this when we
        # start using the MonetaryValue gem to represent money properly

        pl = create_payload
        if pl[:min_bid_override].nil?
          pl[:min_bid_override] = (pl[:monetary_min_bid_override] || pl[:bid]) * 100
        end
        pl[:bid] = (pl[:bid] * 100)
        pl[:min_bid_override] = pl[:bid] if pl[:bid] < 2
        pl[:name] = pl[:title]

        create_with_api(pl)
        id_from_page
        enable
      end

      # Edit method for API editor modules.  Method retrieves payload from #edit_payload and passess along to
      # #updated_with_api
      # @param properties [TestChamber::Properties]
      def edit!(properties)
        payload = edit_payload(properties)
        payload[:bid] = (payload[:bid] * 100) unless payload[:bid].nil?
        @edit_api_body = update_with_api(payload)
      end

      # Iterates through the supported properties of the current offer and adds non-nil values to a payload hash.
      # If properties is provided it will be used to populate the payload, otherwise a new Properties object will
      # be constructed based on offer type
      # @param properties [TestChamber::Properties]
      def init_payload(properties = nil)
        properties ||= self.attributes

        properties.select { |key, value| value.present? }.tap do |payload|
          payload[:partner_id] ||= TestChamber.default_partner_id
          payload[:offer_objective_id] = properties.objective_id
        end
      end

      def upload_banner_creative_via_api
        upload_file_via_api("banner_creative", bannercreative_path)
      end

      def upload_marquee_preview_image_via_api
        upload_file_via_api("marquee_preview_image", marquee_preview_image_path)
      end

      def upload_adicon_via_api
        upload_file_via_api("adicon", icon_path)
      end

      def upload_background_via_api
        upload_file_via_api("background", background_path)
      end

      def id_from_page
        return @id unless @id.nil?
        if @create_api_body
          self.id = @create_api_body["id"]
        else
          raise "We didn't find a response from calling the create api so we can't figure out the id of this object."
        end
      end

      private

      def upload_file_via_api(api_path, file_path)
        obj = JSON.parse('{"name":""}')
        file_name = file_path.split('/')[-1]
        payload = {
          :filename => file_name,
          :file => File.new(file_path, 'rb'),
          :content_type => "image/jpeg"
        }
        if file_name != nil
          response = authenticated_request(:put,
                                           "/api/client/assets/#{api_path}?"\
                                           "form_token=#{form_id}&cid=#{cid}",
                                           payload: payload, format: :file)
          obj = JSON.parse(response[:body])
        end
        obj['name']
      end

    end
  end
end
