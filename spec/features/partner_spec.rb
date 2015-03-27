require 'spec_helper'

describe TestChamber::Partner, type: :feature do
  include_context "I am logged in"
  include_context "using the new look"

  let(:partner_id) { nil }
  let(:reseller_id) { nil }
  let(:rev_share) { nil }
  let(:max_deduction_percentage) { nil }
  let(:discount_all_offer_types) { false }
  let(:offer_discount) { nil }
  let(:offer_discount_expiration) { nil }

  let(:partner) do
    TestChamber::Partner.new(
      :partner_id => partner_id,
      :reseller_id => reseller_id,
      :rev_share => rev_share,
      :max_deduction_percentage => max_deduction_percentage,
      :discount_all_offer_types => discount_all_offer_types,
      :offer_discount => offer_discount,
      :offer_discount_expiration => offer_discount_expiration,
      :use_ui => true # actually use the browser to submit the form
    )
  end

  context "when signed up by a reseller" do
    let(:reseller_id) { "69b1aa24-4e1f-4fb0-9c61-bc0453a698e4" }
    it "has a reseller id" do
      expect(TestChamber::Models::Partner.find(partner.id).reseller_id).to eql("69b1aa24-4e1f-4fb0-9c61-bc0453a698e4")
    end
  end

  context "when not signed up by a reseller" do
    let(:test_id) { partner.id }
    it_validates "it has a UUID"
  end

  context "when using custom revenue options" do
    let(:rev_share) { 0.4 }
    let(:max_deduction_percentage) { 0.2 }
    let(:test_id) { partner.id }
    it_validates "it has a UUID"
  end

  context "when using offer discounts" do
    let(:discount_all_offer_types) { true }
    let(:offer_discount) { 10 }
    let(:test_id) { partner.id }
    it_validates "it has a UUID"
  end
end
