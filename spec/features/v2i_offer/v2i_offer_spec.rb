require 'spec_helper'

describe "Loading test v2i data" do

  include_context "I am logged in"

  def get_secondary_url(v2i_offer)
    destination_page = v2i_offer.click_video_end_card
    doc = Nokogiri::HTML(destination_page[:body])
    doc.css("a").first.attr('href')
  end

  def get_tracking_url(v2i_offer)
    tracking_offer_id = JSON.parse(v2i_offer.create_api_response[:body])["result"]["video_ad"]["video_buttons"][0]["tracking_offer_id"]
    TestChamber::Models::Offer.find(tracking_offer_id).url
  end

  context "Add new ppv offer via api" do

    context "the tracking_offer has an app_store url" do
      let(:publisher_app)   { TestChamber::App.new }
      let(:v2i_offer)       { TestChamber::Offer::V2I.new }
      it "shows the video and redirect user to app store" do
        v2i_offer.complete_click(publisher_app)
        v2i_offer.complete_video_offer_conversion(publisher_app)
        secondary_click_url = get_secondary_url(v2i_offer)
        tracking_url = get_tracking_url(v2i_offer)
        expect(secondary_click_url).to eql tracking_url.sub!('market://search?q=', 'https://play.google.com/store/apps/details?id=')
        v2i_offer.complete_tracking_offer_conversion(publisher_app)
      end
    end

    context "the tracking_offer has a destination url" do
      let(:publisher_app)   { TestChamber::App.new }
      let(:v2i_offer)       { TestChamber::Offer::V2I.new }
      it "sets the destination url for the tracking_offer and redirects user there" do
        v2i_offer.set_tracking_offer_destination_url(v2i_offer.install_tracking_offer.id, v2i_offer.destination_url)
        v2i_offer.complete_click(publisher_app)
        v2i_offer.complete_video_offer_conversion(publisher_app)
        secondary_click_url = get_secondary_url(v2i_offer)
        expanded_macros = Rack::Utils.parse_query URI(secondary_click_url).query

        v2i_offer.class::CLICK_MACROS.each do |key, value|
          key = key.to_s
          expect(expanded_macros[key]).not_to eql(value)
        end
        v2i_offer.complete_tracking_offer_conversion(publisher_app)
      end
    end

    context "the tracking_offer has a third_party url" do
      let(:publisher_app)   { TestChamber::App.new }
      let(:v2i_offer)       { TestChamber::Offer::V2I.new }
      # This depends on TPAT, pending until SQS/SNS manual setup is resolved
      xit "shows the video and send data to third_party url and redirect user to app_store" do
        v2i_offer.set_tracking_offer_tpat_url
        v2i_offer.complete_click(publisher_app)

        v2i_offer.complete_video_offer_conversion(publisher_app)
        # verify that the user has been redirected to the app store
        secondary_click_url = get_secondary_url(v2i_offer)
        tracking_url = get_tracking_url(v2i_offer)
        expect(secondary_click_url).to eql(tracking_url.sub!('market://search?q=', 'https://play.google.com/store/apps/details?id='))

        # verify that all the macors have been expanded
        campaign = v2i_offer.get_campaign
        expanded_macros = Rack::Utils.parse_query URI(campaign["expanded_url"]).query
        v2i_offer.class::CLICK_MACROS.each do |key, value|
          key = key.to_s
          expect(expanded_macros[key]).to_not eql(value)
        end
        v2i_offer.complete_tracking_offer_conversion(publisher_app)
      end

      it "Add new ppv offer via api" do
        publisher_app = TestChamber::App.new

        v2i_offer = TestChamber::Offer::V2I.new
        v2i_offer.complete_click(publisher_app)
        v2i_offer.complete_conversion(publisher_app)

      end
    end
  end

  context "When a V2I and CPI click for the same application interfere" do
    it "Triggers the correct web requests for both clicks" do
      publisher_app = TestChamber::App.new

      # Let's first create a click for our video offer and then make sure we create a click for the end card too.

      v2i_offer = TestChamber::Offer::V2I.new
      v2i_offer.complete_click(publisher_app)
      v2i_offer.complete_video_offer(publisher_app)

      expect(TestChamber::WebRequest.latest).to contain_web_requests_like({
        :path => 'offer_click',
        :predecessor_offer_id => v2i_offer.id,
        :offer_id => v2i_offer.install_tracking_offer.id,
        :advertiser_app_id => v2i_offer.install_tracking_offer.item_id
      }).times(1)

      # Now, for the same advertiser app, we need to make a CPI offer click for this same device.

      cpi_offer = TestChamber::Offer::Install.new(:item_id => v2i_offer.install_tracking_offer.item_id)
      cpi_offer.complete_click(publisher_app)

      # The CPI click should not have a predecessor_offer_id.
      expect(TestChamber::WebRequest.latest).to contain_web_requests_like({
        :path => 'offer_click',
        :offer_id => cpi_offer.id,
        :advertiser_app_id => v2i_offer.install_tracking_offer.item_id
      }).times(1)
      expect(TestChamber::WebRequest.latest).to contain_web_requests_like({
        :path => 'offer_click',
        :predecessor_offer_id => anything,
        :offer_id => cpi_offer.id,
        :advertiser_app_id => v2i_offer.install_tracking_offer.item_id
      }).times(0)

      # A CPI offer reward cannot possibly have a predecessor_offer_id. This is safeguarding against an actual bug.
      cpi_offer.complete_conversion(publisher_app)

      expect(TestChamber::WebRequest.latest).to contain_web_requests_like({
        :path => 'reward',
        :offer_id => cpi_offer.id
      }).times(1)
      expect(TestChamber::WebRequest.latest).to contain_web_requests_like({
        :path => 'reward',
        :predecessor_offer_id => anything,
        :offer_id => cpi_offer.id
      }).times(0)

    end
  end
end
