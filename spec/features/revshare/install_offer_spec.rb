require 'spec_helper'

describe TestChamber::Offer::Install, type: :feature do
  include_context "I am logged in"
  include_context "using the new look"

  let(:kakao_app) { false }
  let(:max_deduction_percentage) { 1.0 }
  let(:offer_discount) { nil }
  let(:reseller) { nil }
  let(:rev_share_override) { nil }
  let(:ignore_cache) { false }

  describe "it should calculate revshare correctly" do
    context "when no store" do
      let(:store) { '' }

      context "with no offer discount" do
        let(:offer_discount) { nil }

        context "70% rev share" do
          let(:rev_share) { 70 }

          context "with a $100 bid" do
            let(:bid) { 100.0 }
            let(:expected_amounts) do
              {
                advertiser_amount: -10000.0,
                publisher_amount: 5775.0,
                tapjoy_amount: 4225.0,
                spend_share: 0.578,
                share_network_costs: 1750.0,
                share_tapjoy_share: 2475.0
              }
            end
            it_validates "assert convert offer!"
          end
        end

        context "50% rev share" do
          let(:rev_share) { 50 }

          context "with a $2.0 bid" do
            let(:bid) { 2.0 }
            let(:expected_amounts) do
              {
                advertiser_amount: -200.0,
                publisher_amount: 82.5,
                tapjoy_amount: 117.5,
                spend_share: 0.413,
                share_network_costs: 35.0,
                share_tapjoy_share: 82.5
              }
            end
            it_validates "assert convert offer!"
          end
        end
      end
    end
  end
end
