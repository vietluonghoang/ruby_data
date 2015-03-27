require 'spec_helper'

describe "Conversions" do
  include_context "I am logged in"
  include_context "using the new look"

  # Conversions trigger chore jobs that will deduct the offer payment value from the advertising partner's balance,
  # deduct overheads (for hosting services, etc) and divide the reminder from the offer's paymnet between tapjoy and the publishing partner
  # based on the revenue share percentage defined for the publishing partner.

  let(:partner_ad) { TestChamber::Partner.new }
  let(:partner_pub) { TestChamber::Partner.new }

  # All partners are created with the following default values, that are relevant for the calculations pertainting to conversions
  #   TestChamber::Parnter::DEFAULT_STARTING_BALANCE = MonetaryValue.new(10000000000, -3)
  #   pending_earnings = 0
  #   pending_earnings_exponent = -3

  let(:publishing_app) { TestChamber::App.new :partner_id => partner_pub.id }
  
  let!(:original_balance) { partner_ad.balance }
  let!(:original_pending_earnings) { partner_pub.pending_earnings }

  context "Generic offers" do
    let(:offer) { TestChamber::Offer::Generic.new(:partner_id => partner_ad.id, :bid => 0.50) }

    it "can register a conversion" do
      offer.convert(publishing_app)
      expect(partner_ad.balance).to eq(original_balance - 50.0)
      expect(partner_pub.pending_earnings).to eq(original_pending_earnings + 20.625)
    end
  end

  context "Mraid offers" do
    let(:offer) { TestChamber::Offer::Mraid.new(:partner_id => partner_ad.id, :bid => 0.01) }

    it "can register a conversion" do
      offer.convert(publishing_app)
      expect(partner_ad.balance).to eq(original_balance - 1.0)
      expect(partner_pub.pending_earnings).to eq(original_pending_earnings + 0.413)
    end
  end

  context "Video offers" do
    let(:offer) { TestChamber::Offer::Video.new(:partner_id => partner_ad.id, :bid => 0.01) }

    it "can register a conversion" do
      offer.convert(publishing_app)
      expect(partner_ad.balance).to eq(original_balance - 1.0)
      expect(partner_pub.pending_earnings).to eq(original_pending_earnings + 0.413)
    end
  end
end
