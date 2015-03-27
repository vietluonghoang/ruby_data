require 'test_chamber/offer/video'

# This is Video to Install offer. In reality this consists of two separate offers; a Video offer with a video button and an install offer called the tracking offer.
# When the video button is created with the video offer it is passed a "tracking_source_offer" which is an install offer. Inside TJS this offer
# is cloned to make a new offer for the same app install. A full V2I offer completion is watching the video, clicking on the video button on the end card
# and installing the app for the install offer.
#
# This class behaves more or less like other offer types. If you call `complete_click` it will click on the video offer.
# The `complete_conversion` method will complete both the video offer, the video button and the install offer.
# You can also complete each part separately with the other complete_ methods.
module TestChamber
  class Offer
    class V2I < Video

      # allow us to just complete the video offer and still have the compound `complete_conversion`
      # implementation that does both
      alias_method :complete_video_offer, :complete_conversion
      attr_accessor :campaign, :install_tracking_offer

      def initialize(options={})
        # This is an install offer which will be cloned
        tracking_source_offer = Install.new(options.clone)
        create_with = options.fetch(:create_with) { :api }
        creator_module = options.fetch(:creator_module) do
          TestChamber::Creator::Video.const_get(create_with.to_s.capitalize)
        end
        properties_class = TestChamber::OfferProperties.const_get("Video#{create_with.to_s.capitalize}")

        super(options.merge(tracking_offer: tracking_source_offer.id,
                            creator_module: creator_module,
                            properties_class: properties_class))

        tracking_offer_id = JSON.parse(@create_api_response[:body])["result"]["video_ad"]["video_buttons"][0]["tracking_offer_id"]

        self.install_tracking_offer = Install.new(options.merge(id: tracking_offer_id))
        self.install_tracking_offer.enable
      end

      def complete_video_offer_conversion(publisher_app, params={})
        complete_video_offer(publisher_app, params)
      end

      def complete_tracking_offer_conversion(publisher_app, params={})
        @install_tracking_offer.complete_conversion(publisher_app, params)
        verify_install_offer_complete_in_statz
      end

      def get_campaign
         response = rest_request(:get, "#{TestChamber.fake_has_offers_url}/campaigns/#{campaign["id"]}/convert")
         JSON.parse(response[:body])
       end

      # called on the completion screen for the video part of a v2i offer
      # This must be called immediately after a video offer is completed so we know we are on the video completion screen with a video button
      def click_video_end_card
        secondary_click_url = find("#cta a")["href"]
        rest_request(:get, secondary_click_url, format: :html)
      end

      def verify_install_offer_complete_in_statz
        statz = TestChamber::Statz.new
        tracking_offer_statz = statz.offer_statz(install_tracking_offer.id, 1.day.ago, Time.now)
        field_name = tracking_offer_statz["data"]["rewarded_installs_plus_spend_data"]["main"]["names"][2]
        total = tracking_offer_statz["data"]["rewarded_installs_plus_spend_data"]["main"]["totals"][2].to_i
        unless field_name == "End Card Clicks"
          raise "Unexpected name for rewarded installs plus spend data: Expected 'End Card Clicks', Actual: '#{field_name}'"
        end
        unless total == 1
          raise "Unexpected total rewarded installs for V2I offer #{id}: Expected '1', Actual '#{total}'"
        end
      end

      def destination_url
        "#{TestChamber.fake_has_offers_url}/v2i?#{Rack::Utils.build_query(CLICK_MACROS)}"
      end

      def set_tracking_offer_destination_url(id, url)
        visit "#{TestChamber.target_url}/statz/#{id}/edit"
        find(:css, '#offer_url_overridden').set(true)
        find(:css, '#offer_url').set url
        fill_in_offer_required_fields
        click_button('Save Changes', :exact => true)
      end

      def set_tracking_offer_tpat_url
        self.tracking_url = get_tracking_url_from_campaign
        visit "#{TestChamber.target_url}/statz/#{@install_tracking_offer.id}/edit"
        find(:css, "#video_secondary_offer_third_party_url").set tracking_url
        fill_in_offer_required_fields
        click_button('Save Changes', :exact => true)
      end

      def set_tracking_offer_platform(*devices)
        visit "#{TestChamber.target_url}/statz/#{@install_tracking_offer.id}/edit"

        devices.each do |device|
          # Chosing an element in Chosen removes it from the collection.
          # Enumerate over the collection again after an element is selected
          index = 0
          all("#offer_device_types option").each do |option|
            index += 1
            if device == option.text
              find("#offer_device_types_chzn").click
              find("#offer_device_types_chzn .chzn-results li:nth-child(#{index})").click
            end
          end
        end

        fill_in_offer_required_fields
        click_button 'Save Changes'
        # Trigger an update to the Offer cache
        refresh_video_offer
      end

      def refresh_video_offer
        visit "#{TestChamber.target_url}/dashboard/statz/#{id}"
        click_link 'Edit Video Offer'
        select('201', :from => 'video_offer_primary_offer_attributes_offer_objective_id')
        click_button 'Update Video Offer'
      end

      def get_tracking_url_from_campaign
        payload = { name: self.title, app_id: app_id, attribution_policy: 'immediate' }
        response = rest_request(:post, "#{TestChamber.fake_has_offers_url}/campaigns", payload: payload)
        campaign = JSON.parse(response[:body])
        campaign["unexpanded_url"]
      end

      def offer_params_group
        'video_offers'
      end

      def offer_params_type
        'video_offer'
      end

      private

      def fill_in_offer_required_fields
        fill_in('Title', :with => 'Test')
        fill_in('Details', :with => 'Test')
        select('101', :from => 'offer_offer_objective_id')
      end
    end
  end
end
