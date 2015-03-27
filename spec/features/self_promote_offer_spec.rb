require 'spec_helper'

describe TestChamber::Offer::Video do
  include_context "I am logged in"

  context "when self_promote_only true" do

    before :all do
      @offer = TC::Offer::Generic.new({self_promote_only: true})
    end

    context "when app and offer have same partner" do
      let(:app) { TC::App.new }

      it "should show the offer on the offerwall" do
        TC::OptSOA.set_top_offers([@offer.id])
        offerwall = app.offerwall
        expect(offerwall.offer_ids).to include @offer.id
      end
    end

    context "when app and offer have different partner" do
      let(:app) do
        partner = TC::Partner.new
        TC::App.new({partner_id: partner.id})
      end

      it "should not show the offer on the offerwall" do
        TC::OptSOA.set_top_offers([@offer.id])
        offerwall = app.offerwall
        expect(offerwall.offer_ids).not_to include @offer.id
      end
    end
  end

  context "when self_promote_only false" do

    before :all do
      @offer = TC::Offer::Generic.new
    end

    context "when app and offer have same partner" do
      let(:app) { TC::App.new }

      it "should show the offer on the offerwall" do
        TC::OptSOA.set_top_offers([@offer.id])
        offerwall = app.offerwall
        expect(offerwall.offer_ids).to include @offer.id
      end
    end

    context "when app and offer have different partner" do
      let(:app) do
        partner = TC::Partner.new
        TC::App.new({partner_id: partner.id})
      end

      it "should show the offer on the offerwall" do
        TC::OptSOA.set_top_offers([@offer.id])
        offerwall = app.offerwall
        expect(offerwall.offer_ids).to include @offer.id
      end
    end
  end
end
