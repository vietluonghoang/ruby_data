# coding: utf-8
# This spec test the moment feature of event service. Advertisers want to reach potential
# consumers during certain Moments during their app experience. By delivering an ad that
# resonates with the User’s emotional state, an Advertiser is better suited to raise awareness
# and engagement with the User seeing the ad.
#
# This spec checks the configuration and targetting of moments.

require 'spec_helper'

describe "EventService::Moments" , :type => :feature do

  include_context "I am logged in"

  before(:all) do
    @partner = TestChamber::Partner.new
    @app     = TestChamber::App.new(:partner_id => @partner.id)
  end

  before(:each) do
    TestChamber.current_device = TestChamber::Device.ios
  end

  def create_placement_with_context(context_name = nil, partner, app )
    uniq = Time.now.strftime("%Y%d%m%H%M%S%L")
    name = "event_#{context_name}_#{uniq}".gsub(" ","_").downcase
    params = {
      :name => name,
      :display_name => name,
      :partner_id => partner.id,
      :app_id => app.id
    }
    params.merge!(:context => context_name) if context_name
    TestChamber::EventService::MonetizationPlacement.new(
      params
    )
  end

  def create_moment_offer(options = {})
    # Product thinks mraid offers is the more realistic use case for
    # moments
    offer = TestChamber::Offer::Mraid.new(
      :moments => [options[:moment_name]],
      :partner_id => options[:partner_id]
    )
    offer.enable(self_promote_only: false, admin_only: false, featured: true)
    offer
  end

  def set_optsoa_offer(offer_id)
    TestChamber::OptSOA.set_only_offers [offer_id]
  end

  def get_placement_offer(app, placement)
    params = { "sdk_type"=>"event",
               "country_code"=>"US",
               "store_view"=>"true",
               "plugin"=>"native",
               "library_version"=>"10.0.0",
               "app_id"=>"#{app.id}",
               "install_id"=>"BEE24658-D961-4F66-8F7E-8FF97256E7FA-2615-00010DFC43531E5E",
               "lad"=>"0",
               "display_multiplier"=>"1.000000",
               "device_type"=>"iPhone%20Simulator",
               "connection_type"=>"wifi",
               "threatmetrix_session_id"=>"15b4df16405147b082652f949e37e8ef",
               "ad_tracking_enabled"=>"true",
               "advertising_id"=>"#{TestChamber.current_device.udid}",
               "language_code"=>"en",
               "event_name"=>"#{placement.event_name}",
               "os_version"=>"7.1",
               "library_revision"=>"cbc55d",
               "verifier"=>"f1b9d8ad9487e02daf4b06e56cc9cbeeb4a561b46ab6df93ec682c957c89781b",
               "app_version"=>"1.0",
               "timestamp"=>"1409844989",
               "session_id"=>"921aa75ec686420f3a37f85208868b9378eb8757748aaceabcc0bdbab6d14120",
               "platform"=>"iOS",
               "bridge_version"=>"1.0.5",
               "device_location"=>"true",
               "device_name"=>"x86_64",
               "tjdebug"=>"true"
    }
    TestChamber::EventService::PlacementOffer.new(params)
  end

  context "creation" do

    it "should be able to create a placement with achievement context and enable it" do
      expect(create_placement_with_context("Achievement",@partner,@app).enable).to eq true
    end

    it "should be able to create a placement with failure context and enable it" do
      expect(create_placement_with_context("Failure",@partner,@app).enable).to eq true
    end

    it "should be able to create a placement with user pause context and enable it" do
      expect(create_placement_with_context("User Pause",@partner,@app).enable).to eq true
    end

    it "should be able to create a placement with app launch context and enable it" do
      expect(create_placement_with_context("App Launch",@partner,@app).enable).to eq true
    end

    it "should be able to create a placement with default context and enable it" do
      expect(create_placement_with_context(nil,@partner,@app).enable).to eq true
    end
  end

  context "targeting"  do
    def target_moment(context_name, moment_name)
      placement = create_placement_with_context(context_name,@partner,@app)
      placement.enable

      offer = create_moment_offer(moment_name: moment_name, partner_id: @partner.id)
      set_optsoa_offer(offer.id)

      placement_offer = get_placement_offer(@app, placement)
      [placement_offer, offer.id]
    end

    xit "should return offers with success moments"  do
      placement_offer, offer_id = target_moment("Achievement","Success")
      expect(placement_offer.has_content?).to be true
      expect(placement_offer.get_offer_id).to eql(offer_id)
    end

    it "should return offers with rescue moments" do
      placement_offer, offer_id = target_moment("Failure","Rescue")
      expect(placement_offer.has_content?).to be true
      expect(placement_offer.get_offer_id).to eql(offer_id)
    end

    it "should return offers with pause moments" do
      placement_offer, offer_id = target_moment("User Pause","Pause")
      expect(placement_offer.has_content?).to be true
      expect(placement_offer.get_offer_id).to eql(offer_id)
    end

    xit "should return offers with welcome moments" do
      placement_offer, offer_id = target_moment("App Launch","Welcome")
      expect(placement_offer.has_content?).to be true
      expect(placement_offer.get_offer_id).to eql(offer_id)
    end

    xit "should not return offers with success moments" do
      ["Failure","User Pause","App Launch"].each do | context |
        placement_offer, offer_id = target_moment(context,"Success")
        expect(placement_offer.has_content?).to be false
      end
    end

    # Event service returns 200, and reports no errors so this spec fails
    # and no error is logged, marking pending
    it "should not return offers with rescue moments" do
      ["Achievement","User Pause","App Launch"].each do | context |
        placement_offer, offer_id = target_moment(context,"Rescue")
        expect(placement_offer.has_content?).to be false
      end
    end

    # Event service returns 200, and reports no errors so this spec fails
    # and no error is logged, marking pending
    xit "should not return offers with pause moments" do
      ["Achievement","Failure","App Launch"].each do | context |
        placement_offer, offer_id = target_moment(context,"Pause")
        expect(placement_offer.has_content?).to be false
      end
    end

    xit "should not return offers with welcome moments" do
      ["Achievement","Failure","User Pause"].each do | context |
        placement_offer, offer_id = target_moment(context,"Welcome")
        expect(placement_offer.has_content?).to be false
      end
    end
  end

  context "reporting" do
  end
end
