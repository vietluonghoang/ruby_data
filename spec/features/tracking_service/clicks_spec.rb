require 'spec_helper'

# Integration tests for the public endpoints served by ClickController in tracking_service
describe "TrackingService::Clicks" do
  include_context "I am logged in"
  include_context "using the new look"

  CLICK_TYPES = [{:route=>'generic', :offer=>TestChamber::Offer::Generic},
                 {:route=>'video_offer', :offer=>TestChamber::Offer::Video},
                 {:route=>'mraid', :offer=>TestChamber::Offer::Mraid},
                 {:route=>'app', :offer=>TestChamber::Offer::Install}]
  before(:all) do
    PUBLISHER_PARTNER = TestChamber::Partner.new
    ADVERTISER_PARTNER = TestChamber::Partner.new
  end

  context "all actions create a click" do
    CLICK_TYPES.each do |obj|
      context "/click/#{obj[:route]}" do
        let(:publisher_app) { TestChamber::App.new(partner_id: PUBLISHER_PARTNER.id) }
        let(:offer) { obj[:offer].new(partner_id: ADVERTISER_PARTNER.id) }

        it "creates a click associated with the offer, device, and publisher" do
          publisher_app.open_app
          click = offer.complete_click(publisher_app)
          expect(click).not_to eq(nil)
          expect(click.attribute("type")).to eq(offer.click_action)
          expect(click.attribute("offer_id")).to eq(offer.id)
          expect(click.attribute("udid")).to eq(TestChamber.current_device.normalized_id)
          expect(click.attribute("publisher_app_id")).to eq(publisher_app.id)
          expect(click.attribute("publisher_partner_id")).to eq(PUBLISHER_PARTNER.id)
        end
      end
    end
  end

  context "/click/video_offer" do
    it 'creates a conversion' do
      pending 'waiting for ConversionTrackingJob to be working in tracking_service'
      # Should be able to use ReengagementOffer#complete_conversion to test this
      fail
    end
  end

  context "/click/mraid" do
    it 'creates a conversion' do
      pending 'waiting for ConversionTrackingJob to be working in tracking_service'
      # Should be able to use ReengagementOffer#complete_conversion to test this
      fail
    end
  end

  context "/click/reengagement" do
    let(:publisher_app) { TestChamber::App.new(partner_id: PUBLISHER_PARTNER.id) }
    let(:advertiser_app) { TestChamber::App.new(partner_id: ADVERTISER_PARTNER.id) }
    let(:reengagement_offer) { TestChamber::Offer::Reengagement.new(app_id: advertiser_app.id, partner_id: ADVERTISER_PARTNER.id) }
    # Waiting for reengament offer branch to be merged
    xit "creates a click" do
      publisher_app.open_app
      click = reengagement_offer.complete_click(publisher_app)
      expect(click).not_to eq(nil)
      expect(click.attribute("type")).to eq("reengagement")
      expect(click.attribute("offer_id")).to eq(reengagement_offer.id)
      expect(click.attribute("udid")).to eq(TestChamber.current_device.normalized_id)
      expect(click.attribute("publisher_app_id")).to eq(publisher_app.id)
      expect(click.attribute("publisher_partner_id")).to eq(PUBLISHER_PARTNER.id)
    end

    it 'creates a conversion' do
      pending 'waiting for ConversionTrackingJob to be working in tracking_service'
      # Should be able to use ReengagementOffer#complete_conversion to test this
      fail
    end
  end

  context "/click/app" do
    #TODO: these tests require jobs, or device service functionality that is not built yet
    xit 'pushes a increment_clicks on the spyglass client'
    xit 'updates device last run time'
    xit 'kicks off a ConversionTrackingJob'
  end

  context "/click/survey" do
    let(:publisher_app) { TestChamber::App.new(partner_id: PUBLISHER_PARTNER.id) }
    let(:survey_offer) { TestChamber::Offer::Survey.new(partner_id: ADVERTISER_PARTNER.id) }
    #TODO waiting for Offer::Survey creation to be supported
    xit "creates a click" do
      publisher_app.open_app
      click = survey_offer.complete_click(publisher_app)

      expect(click).not_to eq(nil)
      expect(click.attribute("type")).to eq("survey")
      expect(click.attribute("offer_id")).to eq(survey_offer.id)
      expect(click.attribute("udid")).to eq(TestChamber.current_device.normalized_id)
      expect(click.attribute("publisher_app_id")).to eq(publisher_app.id)
      expect(click.attribute("publisher_partner_id")).to eq(PUBLISHER_PARTNER.id)
    end

    #TODO: these tests require jobs, or device service functionality that is not built yet
    xit 'pushes a increment_clicks on the spyglass client'
    xit 'updates device last run time'
    xit 'kicks off a ConversionTrackingJob'
  end

  context "/click/action" do
    let(:publisher_app) { TestChamber::App.new(partner_id: PUBLISHER_PARTNER.id) }
    let(:action_offer) { TestChamber::Offer::Action.new(partner_id: ADVERTISER_PARTNER.id) }
    #Waiting for offer properties for Action to be merged
    xit "creates a click associated with the offer, device, and publisher" do
      publisher_app.open_app
      click = action_offer.complete_click(publisher_app)
      expect(click).not_to eq(nil)
      expect(click.attribute("type")).to eq("action")
      expect(click.attribute("offer_id")).to eq(action_offer.id)
      expect(click.attribute("udid")).to eq(TestChamber.current_device.normalized_id)
      expect(click.attribute("publisher_app_id")).to eq(publisher_app.id)
      expect(click.attribute("publisher_partner_id")).to eq(PUBLISHER_PARTNER.id)
    end

    #TODO: these tests require jobs, or device service functionality that is not built yet
    xit 'pushes a increment_clicks on the spyglass client'
    xit 'updates device last run time'
    xit 'kicks off a ConversionTrackingJob'
  end
end
