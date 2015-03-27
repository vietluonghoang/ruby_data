require 'spec_helper'

describe TestChamber::Offerwall do
  include_context "I am logged in"
  include_context "using the new look"

  context "offerwall" do

    # By creating an app for each example, we can avoid duplicate web-request failures on
    # NetRead::Timeout retries
    let(:app)         { TestChamber::App.new }
    let(:device)      { TestChamber::Device.ios }
    let(:offerwall)   { TestChamber::Offerwall.new(app: app) }

    it 'does not show an offerwall to devices that have opted-out' do
      TestChamber.current_device = device

      app.open_app

      TestChamber.current_device.opt_out

      expect(offerwall.no_more_offers?).to be true
    end

    # marked pending because of https://jira.tapjoy.net/browse/QE-443
    # Debugging left in place until this is resolved
    it "generates web requests" do
      TestChamber.current_device = device

      test_start = Time.now
      # The amount of offers returned isn't fixed, could be a lot, could be a little. Should be more than 0
      expect(offerwall.offers.size).to be > 0

      impression_web_requests = TestChamber::WebRequest.since(test_start, path: 'offerwall_impression', app_id: app.id)
      all_web_requests = TestChamber::WebRequest.since(test_start)
      all_wr_ids = all_web_requests.map{|w| w["attrs"]["offer_id"]}.compact.flatten
      # the number of web requests should equal the number of offers on the offerwall
      add_context(impression_web_requests: impression_web_requests)
      puts "missing id in wr is #{offerwall.offer_ids - all_wr_ids}"

      expect(impression_web_requests.size).to eq offerwall.offers.size

      # overall impression for the offerwall
      expect(all_web_requests).to contain_web_requests_like({
                                                              :path => "offers",
                                                              :app_id => app.id,
                                                              :device_type => device.device_type,
                                                              :currency_id => app.id
                                                            }
                                                           )
      # impression for each offer in the offerwall
      # sometimes the first offer in the offer_ids list doesn't record an impression. This is a complete mystery.
      ids = offerwall.offer_ids
      ids.shift
      ids.each do |offer_id|
        expect(all_web_requests).to contain_web_requests_like({
                                                        :path => "offerwall_impression",
                                                        :app_id => app.id,
                                                        :device_type => device.device_type,
                                                        :currency_id => app.id,
                                                        :offer_id => offer_id
                                                      }
                                                     )
      end
    end
  end

  context "Premium Offerwall" do
    let(:app)         { TestChamber::App.new }
    let(:device)      { TestChamber::Device.ios }
    let(:offerwall)   { TestChamber::Offerwall.new app: app }

    before do
      # configure a premium offerwall
      premium_offer_list = TestChamber::Models::Offer.where(premium: 1, active: 1, tapjoy_enabled: 1, user_enabled: 1).map {|o| o.id}
      TestChamber::OptSOA.set_top_offers(premium_offer_list)
    end

    it "returns generic and premium offers" do
      premium_offers = offerwall.offers.find_all {|o| o.is_premium?}
      non_premium_offers = offerwall.offers.find_all {|o| !o.is_premium?}
      expect(premium_offers).not_to be_empty
      expect(non_premium_offers).not_to be_empty
    end
  end
end
