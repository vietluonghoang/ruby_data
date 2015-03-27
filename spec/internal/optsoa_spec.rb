require 'spec_helper'

describe TestChamber::OptSOA do

  include_context "I am logged in"

  let(:response) do
    { 'hey' => 'you', 'woo' => 'testing' }
  end

  let(:offer_ids) do
    4.times.map { SecureRandom.uuid }
  end

  let(:response_device_id) { TestChamber.current_device.normalized_id }

  let(:soa_response) { TestChamber::OptSOA.response_for_device(response_device_id) }

  let(:response_offers) do
    soa_response['offers'].map {|offer| offer['id']}
  end

  context "setting a response" do

    context "for the current device" do

      before { TestChamber::OptSOA.set_response response }

      context "requesting offers for that device" do

        it "provides the response" do
          expect(soa_response).to eq(response)
        end

      end

    end

    context "for any device" do

      context "requesting offers for a non-registered device" do

        before { TestChamber::OptSOA.set_response response, device_id: :all }

        # Put OptSOA in a sane state after test
        after { TestChamber::OptSOA.set_top_offers [], device_id: :all }

        let(:app) { TestChamber::App.new }
        let(:offerwall) { TestChamber::Offerwall.new(app: app) }
        let(:offerwall_offer) { offerwall.offers.reject {|offer| offer.is_premium?}.first }

        it "provides the response for any device" do
          expect(soa_response).to eq(response)
        end

        it "puts the offer at the top of the offerwall" do
          offer = TestChamber::Offer::Generic.new
          TestChamber::OptSOA.set_top_offers([offer.id])
          # Should be second offer in offerwall (top)
          expect(offerwall.offer_ids).to include(offerwall_offer.id)
          expect(offerwall_offer.id).to eq(offer.id)
        end

      end

    end

  end

  context "setting top offers response" do

    context "for the current device" do

      before { TestChamber::OptSOA.set_top_offers offer_ids }

      after { TestChamber::OptSOA.set_top_offers [], device_id: :all }

      context "requesting offers for that device" do

        it "provides the given offers at the top" do
          expect(response_offers.take(4)).to eq(offer_ids)
        end

      end

    end

    context "for any device" do

      before { TestChamber::OptSOA.set_top_offers offer_ids, device_id: :all }

      after { TestChamber::OptSOA.set_top_offers [], device_id: :all }

      context "requesting offers for a non-registered device" do

        let(:response_device_id) { SecureRandom.uuid.gsub '-', '' }

        it "provides the given offers at the top for any device" do
          expect(response_offers.take(4)).to eq(offer_ids)
        end

      end

    end

  end

  context "setting only offers response" do

    context "for the current device" do

      before { TestChamber::OptSOA.set_only_offers offer_ids }

      after { TestChamber::OptSOA.set_only_offers [], device_id: :all }

      it "provides only the given offers" do

        expect(response_offers).to eq(offer_ids)
      end

    end

    context "for any device" do

      before { TestChamber::OptSOA.set_only_offers offer_ids, device_id: :all }

      after { TestChamber::OptSOA.set_only_offers [], device_id: :all }

      context "requesting offers for a non-registered device" do

        let(:response_device_id) { SecureRandom.uuid.gsub '-', '' }

        it "provides only the given offers for any device" do
          expect(response_offers).to eq(offer_ids)
        end

      end

    end

  end

end
