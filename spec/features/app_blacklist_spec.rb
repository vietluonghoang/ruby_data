require 'spec_helper'

describe "app blacklist" do
  include_context "I am logged in"

  let(:app) { TestChamber::App.new(platform: "android") }
  let(:app1) { TestChamber::App.new(platform: "android") }

  context "offer has app blacklist defined" do
    it "pass the offer if app is the only one in the blacklist" do
      offer = TestChamber::Offer::Generic.new
      offer.enable(admin_only: false)
      offer.change_app_blacklist([app.id])

      TestChamber::OptSOA.set_only_offers [offer.id]

      offerwall = TestChamber::Offerwall.new(app: app)
      expect(offerwall.offers.map(&:id)).to_not include(offer.id)
    end

    it "pass the offer if app is in the blacklist with other apps" do
      offer = TestChamber::Offer::Generic.new
      offer.enable(admin_only: false)
      offer.change_app_blacklist([app.id,app1.id])

      TestChamber::OptSOA.set_only_offers [offer.id]

      offerwall = TestChamber::Offerwall.new(app: app)
      expect(offerwall.offers.map(&:id)).to_not include(offer.id)
    end

    it "shows the offer on offerwall if app is not in the blacklist" do
      offer = TestChamber::Offer::Generic.new
      offer.enable(admin_only: false)
      offer.change_app_blacklist([app1.id])

      TestChamber::OptSOA.set_only_offers [offer.id]

      offerwall = TestChamber::Offerwall.new(app: app)
      expect(offerwall.offers.map(&:id)).to include(offer.id)
    end
  end

  context "offer does not have app blacklist defined" do
    it "shows the offer on offerwall" do
      offer = TestChamber::Offer::Generic.new
      offer.enable(admin_only: false)

      TestChamber::OptSOA.set_only_offers [offer.id]

      offerwall = TestChamber::Offerwall.new(app: app)
      expect(offerwall.offers.map(&:id)).to include(offer.id)
    end
  end

end
