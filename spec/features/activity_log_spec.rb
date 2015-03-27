require 'spec_helper'

describe "Activity logger view" do
  include_context "I am logged in"

  context "offer logs" do
    before :all do
      @partner = TestChamber::Partner.new
      @offer = TestChamber::Offer::Video.new(partner_id: @partner.id)
    end

    let(:activity_log) { TestChamber::ActivityLog.new(partner_id: @partner.id) }

    it "Displays offer logs when offers are created" do
      expect(activity_log.offer_ids).to include(@offer.id)
    end

    it "Displays offer logs when offer logs are modified" do
      @offer.enable
      expect(activity_log.modified_object_ids).to include(@offer.id)
    end
  end

  context "external logs" do
    let(:placement) { TestChamber::EventService::Placement.new }
    let(:activity_log) { TestChamber::ActivityLog.new(object_id: placement.id) }

    # Waiting on events team to complete the placement service libs to complete this spec

    xit "Displays event logs" do
      expect(activity_log["Controller"]).to eq "::PlacementService::PlacementController"
    end
  end
end
