module TestChamber
  class Offer
    class Video < Offer

      def initialize(options={})
        # video offers require a tracking offer, if one is not provided use a generic offer
        unless options[:tracking_offer]
          tracking_options = TestChamber::OfferProperties::GenericUiV1.conform_to(options)
          tracking_offer = TestChamber::Offer::Generic.new(tracking_options)
          options[:tracking_offer] = tracking_offer.id
        end

        super(options)

        # we need the video duration to know how long to wait for conversion
        begin
          video = FFMPEG::Movie.new(video_path)
          @video_duration = video.duration
        rescue SystemCallError => e
          raise "Unable to open video file, please make sure ffmpeg is installed" if e.message.index('ffmpeg')
          raise e
        end
        encode
      end

      # When a video offer is created the resources field in the db is null, this gets populated by the zencoder callback
      #
      # @return [true, false] boolean indicating if there is a value in resources field
      def encoded?
        return encoded if encoded
        model = TestChamber::Models::VideoOffer.find(id)
        self.encoded = !model.resources.blank?
      end

      # Posts fake json data to the zencoder callback controller to make offers "encoded"
      #
      # @return [true, false] boolean indicating the success of the encode call
      def encode
        return true if encoded?

        # real zencoding results in several encodings available at the urls in the callback json
        #  we will just use the original video url for everthing
        #
        # see the zencode notifications version 2 documentation - https://app.zencoder.com/docs/guides/getting-started/notifications
        model = TestChamber::Models::VideoOffer.find(id)
        zencode_payload = {
          job:  { pass_through: id },
          outputs: [
            { state: "finished", label: "legacy", url: model.video_url },
            { state: "finished", label: "baseline", url: model.video_url },
            { state: "finished", label: "advanced", url: model.video_url },
            { state: "finished", label: "aggressive", url: model.video_url }
          ]
        }

        authenticated_request(:post, 'dashboard/zencoder/callback', payload: zencode_payload)

        # this is a hack to get around a cacheing issue in TJS
        #  1. a video offer is created by test chamber
        #  2. a model/video_offer and correspoding model/offer object are created in TJS
        #  3. post fake zencoder json to zencoder callback in TJS
        #  4. offerwall filtering skips video offers that have not been zencoded
        #     - zencoder callback updates video_offer.resourcess in TJS, but offer is still filtered out due to cacheing
        #     - see model/offer.is_encoding_complete?
        #
        # get around this bug by "updating" the video_offer to clear the cached object
        authenticated_request(:put, "api/client/video_ads/#{id}")
        encoded?
      end

      def offer_params_group
        'video_offers'
      end

      def offer_params_type
        'video_offer'
      end

      def click_action
        'video'
      end

      # Overriding from Offer class for video offers created with both API and UI
      # parse out the params from the custom tjvideo url presented for video offers
      # to get the followup urls and use those instead of putting them together ourselves
      def click_with_rest!(publisher_app)
        visit display_offer_url(publisher_app)
        offer_item_url = find(".offer-item a")["href"]

        if offer_item_url.start_with?('tjvideo://')
          params = CGI.parse(offer_item_url.sub(%r{^tjvideo://}, ''))
          self.video_complete_url = params['video_complete_url'].first
          self.click_url = params['click_url'].first

          unless video_complete_url
            raise "Unable to find video_complete_url in tjvideo:// url params #{params}"
          end
          unless click_url
            raise "Unable to find click_url in tjvideo:// url params #{params}"
          end
          unless params['video_id'].first == id
            raise "The id in the url found on the page doesn't match the video offer we're working with. I don't even know what's going on anymore. Found #{params['video_id']} but our id is #{id}"
          end
        else
          raise "Expecting a url starting with 'tjvideo://' but found #{offer_item_url}"
        end

        rest_request(:get, click_url, format: :html)
        click
      end
    end
  end
end
