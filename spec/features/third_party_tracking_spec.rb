require 'spec_helper'
require 'pry-byebug'
require 'utils/object_encryptor'

describe TestChamber::Offer::Install do
  include_context "I am logged in"

  let(:app) { TestChamber::App.new }
  let(:offer) { described_class.new(tpat_enabled: true) }

  context "it simulates the third_party tracking" do

    # This test doesn't work on TIAB because SNS and SQS are improperly configured.
    # See: https://github.com/Tapjoy/third_party_attribution/pull/32 and
    # https://jira.tapjoy.net/browse/QE-647
    it "should simulate third_party tracking" do
      # click on the offer, and send the click to fakehasoffers
      offer.click!(app)
      # This will trigger the fakehasoffer to send the app_install conversion to sns_proxy
      app.convert_offer(offer)

      expanded_macros = Rack::Utils.parse_query URI(offer.campaign["expanded_url"]).query

      TestChamber::Offer::CLICK_MACROS.each do |key, value|
        key = key.to_s
        device = TestChamber.current_device
        advertising_id = device.try(:advertising_id)
        mac_address = device.try(:mac_address)
        raw_advertising_id = device.try(:raw_advertising_id)
        android_id = device.try(:android_id)
        raw_android_id = device.try(:raw_android_id)
        device_click_ip = device.try(:device_click_ip)
        case key
        when "generic_source"
          expect(expanded_macros[key]).to eq(TestChamber::ObjectEncryptor.encrypt("#{app.id}.#{offer.partner_id}",false))
        when "external_uid"
          expect(expanded_macros[key]).to eq(Digest::MD5.hexdigest("#{device.advertising_id}.#{offer.partner_id}"+'a#X4cHdun84eB9=2bv3fG^RjNe46$T'))
        when "hashed_mac"
          expect(expanded_macros[key]).to eq(mac_address ? Digest::SHA1.hexdigest(mac_address) : "")
        when "advertising_id"
          expect(expanded_macros[key]).to eq(advertising_id ? advertising_id : "")
        when "raw_ad_id"
          expect(expanded_macros[key]).to eq(raw_advertising_id ? raw_advertising_id : advertising_id)
        when "hashed_ad_id"
          expect(expanded_macros[key]).to eq(advertising_id ? Digest::SHA1.hexdigest(advertising_id) : "")
        when "android_id"
          expect(expanded_macros[key]).to eq(android_id ? android_id : "")
        when "raw_android_id"
          expect(expanded_macros[key]).to eq(raw_android_id ? raw_android_id : "")
        when "hashed_android_id"
          expect(expanded_macros[key]).to eq(android_id ? Digest::SHA1.hexdigest(android_id) : "")
        when "hashed_raw_android_id"
          expect(expanded_macros[key]).to eq(raw_android_id ? Digest::SHA1.hexdigest(raw_android_id) : "")
        when "click_key"
          expect(expanded_macros[key]).to eq("#{device.normalized_id}.#{offer.item_id}")
        end
      end

    end
  end

end
