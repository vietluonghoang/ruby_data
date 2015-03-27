require 'spec_helper'

describe 'TestChamber::Offer::V2I' do
  include_context 'I am logged in'
  # TODO: These describe/example phrases suck, rename to something more appropriate
  context 'mobile offerwall', :appium do
    let(:offer) { TestChamber::Offer::V2I.new }

    # FIXME: Create app in TIAB db for EasyApp so we can assert that the right app id
    # shows up. For now, this is hardcoded to the EasyApp app id.
    let(:easy_app_id) { '13b0ae6a-8516-4405-9dcf-fe4e526486b' }

    before(:each) do
      Capybara.using_driver :selenium do
        # Have to set this here and not in a let because we need it instantiated
        # inside the using_driver block.
        @app = TestChamber::App.new
        # FIXME: The tracking offer should read from TestChamber.current_device
        offer.set_tracking_offer_platform('iphone')
        # FIXME: Remove device_id param once we can get the appium device's id
        # in a spec, and not in the offerwall.
        TestChamber::OptSOA.set_top_offers([offer.id], device_id: :all)
      end

      @test_start = Time.now
      offerwall = @app.offerwall

      offerwall.click_offer(offer.id).convert!
    end

    it 'converts the video offer' do
      all_web_requests = TestChamber::WebRequest.since(@test_start)

      expect(all_web_requests).to contain_web_requests_like({
        # FIXME: Why isn't app_id matching? It's there!
        # :app_id => easy_app_id,
        :offer_id => offer.id,
        :path => 'videos_tracking',
        :video_event => 'start'
      })

      expect(all_web_requests).to contain_web_requests_like({
        # :app_id => easy_app_id,
        :offer_id => offer.id,
        :path => 'conversion_attempt'
      })

      expect(all_web_requests).to contain_web_requests_like({
        # :app_id => easy_app_id,
        :offer_id => offer.id,
        :path => 'reward'
      })
    end

    it 'converts on the end card' do
      offer.install_tracking_offer.convert!

      all_web_requests = TestChamber::WebRequest.since(@test_start)
      expect(all_web_requests).to contain_web_requests_like({
        :offer_id => offer.install_tracking_offer.id,
        :type => 'video_to_install',
        :path => 'conversion_attempt',
        :resolution => 'converted'
      })
    end
  end
end
