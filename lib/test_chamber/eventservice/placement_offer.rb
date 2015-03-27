module TestChamber
  module EventService
    # A Placement offer is the offer returned by a placement call.
    # This is a adunit containing an offer.
    class PlacementOffer
      include Capybara::DSL

      attr_reader :params
      attr_reader :offer_id

      def initialize(options = {})
        response = RestClient.get("#{TestChamber.target_url}/event-service/events?#{options.to_query}")
        unless [200,204].include?(response.code)
          raise "PlacementOffer did not recv a valid response : #{response.code} "
        end
        @has_content = response.code == 200
        @offer_page  = response.body if @has_content
      end

      def has_content?
        @has_content
      end

      def get_offer_id
        p = Nokogiri::HTML(@offer_page)
        url = get_conversion_url(p)
        offer_id_from_url(id_url(url))
      end

      private

      def get_conversion_url(page)
        page.css('script').map do | t |
          t.text.scan(/conversion_url:[ \"]*(.*)[\"]/)[0][0] unless t.text == ''
        end.compact.first
      end

      def id_url(url)
        URI.parse(url)
      end

      def offer_id_from_url(url)
        encrypted_params = CGI::parse(url.query)
        @params = ObjectEncryptor.decrypt(encrypted_params['data'].first)

        if url.path.include?('/ad_unit/convert')
          @offer_id = @params[:offer_id]
        else
          raise "Can't parse offer_id out of url #{url}"
        end
      end
    end
  end
end
