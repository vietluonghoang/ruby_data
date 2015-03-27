require 'spec_helper'

describe "device os targeting" do
  include_context "I am logged in"

  before(:all) do
    @app = TestChamber::App.new(platform: "android")
  end

  context "with compatible version" do
    it 'should show on offerwall when versions match' do
      offer = TestChamber::Offer::Generic.new
      offer.enable(self_promote_only: false, admin_only: false)
      offer.target_devices("android")
      offer.target_os(Android: ['4.4'])

      TestChamber::OptSOA.set_only_offers [offer.id]

      # default offerwall os/version is android 4.4
      offerwall = TestChamber::Offerwall.new(app: @app)
      expect(offerwall.offers.map(&:id)).to include(offer.id)
    end

    it 'should show on offerwall when version is targeted' do
      offer = TestChamber::Offer::Generic.new
      offer.enable(self_promote_only: false, admin_only: false)
      offer.target_devices("android")
      offer.target_os(Android: ['4.4', '4.3'])

      TestChamber::OptSOA.set_only_offers [offer.id]

      offerwall = TestChamber::Offerwall.new(app: @app)
      expect(offerwall.offers.map(&:id)).to include(offer.id)
    end
  end

  context "wrong version" do
    it 'should not show on offerwall' do
      TestChamber.current_device = TestChamber::Device.android_10_point_1(os_version: '4.3')
      offer = TestChamber::Offer::Generic.new
      offer.enable(self_promote_only: false, admin_only: false)
      offer.target_devices("android")
      offer.target_os(Android: ['4.4'])

      TestChamber::OptSOA.set_only_offers [offer.id]

      offerwall = TestChamber::Offerwall.new(app: @app)
      expect(offerwall.offers.map(&:id)).to_not include(offer.id)
    end
  end

  context "wrong operating system" do
    it 'should not show on offerwall' do
      offer = TestChamber::Offer::Generic.new
      offer.enable(self_promote_only: false, admin_only: false)
      offer.target_devices("iphone", "ipad", "itouch")
      offer.target_os(iOS: ['7.1'])

      TestChamber::OptSOA.set_only_offers [offer.id]

      offerwall = TestChamber::Offerwall.new(app: @app)
      expect(offerwall.offers.map(&:id)).to_not include(offer.id)
    end
  end
end
