# coding: utf-8
=begin
* OFFER CONVERSION METRICS used in this SPEC *
***** Definitions of how these metrics work and where they get retrieved from database *****

advertiser_amount = If offer partner_id is same as currency partner_id then it returns 0 or else it returns offer_payment which is the field in offers table; that is advertiser_amount.
publisher_amount = If we subtract all of these: advertiser_amount, network_costs and net_of_costs, it gives publisher_amount which is partner_rev_share field in currencies table.
tapjoy_amount = If we subtract advertiser_amount from publisher_amount, it gives tapjoy_amount. Tapjoy_amount is the amount with out deducting network_costs is considered as Gross Income.
spend_share = Ratio between publisher_amount and advertiser_amount.
share_network_costs = 16.5% of the advertiser amount is called share_network_costs.
share_advertiser_amount = Same as adertiser_amount; this is an artifact of how multiple share_types are calculated then stored in the conversion_revenue_shares table.
share_publisher_amount = Same as publisher_amount; this is an artifact of how multiple share_types are calculated then stored in the conversion_revenue_shares table.
share_tapjoy_share = Remaining amount left after deducting network_costs from tapjoy_amount is called share_tapjoy_share considered as net income.
share_net_of_costs = We calculate this only while dealing with Kakao and SKT; google and gFan does not cost;
KAKAO share_net_of_costs = Net of cost for kakao is fixed which is 17.5% is taken from advertiser_amount which gives share_net_of_costs;
SKT share_net_of_costs = SKT or anyone else it will be 10.2% is taken from advertiser_amount which gives share_net_of_costs.
offer_discount = It can be set at partner level, if it’s set then advertiser_amount will be offer_discount times bid.
bid  =  Is set during offer creation and will be used to calculate advertiser_amount.
rev_share =  Is share of offer revenue that publisher gets.
max_deduction_percentage = The maximum percentage that a publisher's rev share can be lowered to recover marketing credits and network operating costs. Must be number between 0 and 1. Example: A pub with rev share of 70% and max deduction percentage of 7% will have an effective rev share between 65-70%. (70% * 93% = 65%)
reseller_rev_share = This will act as publisher_rev_share in context; used to calculate regular publisher_amount.
rev_share_override = This means currency’s rev_share can be changed at app currencies page, if set overrides the publisher’s rev_share.

***** Below are Formulae to show how expected_amounts are calculated *****

for example:
context "with 10% offer discount" do
        let(:offer_discount) { 10 }

        context "70% rev share" do
          let(:rev_share) { 70 }

          context "with a $100 bid" do
            let(:bid) { 100.0 }
            let(:expected_amounts) do
              {
                advertiser_amount: -9000.0,  (advertiser_amount = offer_discount * bid ==> -90 * 100 = -9000)
                publisher_amount: 5355.0, (publisher_amount = {advertiser_amount - share_network_costs - net_of_costs} * rev_share ==> {9000 - 1350 - nil} * 0.7 = 5355)
                tapjoy_amount: 3645.0, (tapjoy_amount =  advertiser_amount - publisher_amount ==> 9000 - 5355 = 3645)
                spend_share: 0.595, (spend_share =  publisher_amount / advertiser amount ==> 5355 / 9000 = 0.595)
                    share_network_costs: 1350.0, (share_network_costs = advertiser_amount * % of network_fee ==> 9000 * 0.15 = 1350)  IMP: network_fee has changed to 17.5% recently so expected_amounts may vary
                    share_tapjoy_share: 2295.0 (share_tapjoy_share = tapjoy_amount - share_network_costs ==> 3645 - 1350 = 2295)
              }
            end
            assert_convert_offer!
          end
        end

for example: rev_share will be overridden by rev_share_override as in formulae below
  context "with a rev share override" do
        let(:rev_share) { 60 }
        let(:offer_discount) { 15 }

        context "with a $2 bid" do
          let(:bid) { 2.0 }

          context "with a 90% rev share override" do
            let(:rev_share_override) { 0.90 }
            let(:expected_amounts) do
              {
                advertiser_amount: -170.0,
                publisher_amount: 130.050, (publisher_amount = {advertiser_amount - share_network_costs - net_of_costs} * rev_share_override ==> {170 - 25.5085} * 0.9 = 130.040)
                tapjoy_amount: 39.950,
                spend_share: 0.765,
                share_network_costs: 25.50,
                share_tapjoy_share: 14.45
              }
            end
            assert_convert_offer!
          end

for example: rev_share calculation when we have max_deduction_percentage = (rev_share % * max_deduction_percentage %) ==> 70% * 99% = 69% is rev_share
  context "with a max deduction percentage" do
        let(:rev_share) { 70 }
        let(:store) { '' }
        let(:offer_discount) { 10 }

        context "of 10%" do
          let(:max_deduction_percentage) { 0.10 }

             context "with a $0.0325 bid" do
               let(:bid) { 0.0325 }
               let(:expected_amounts) do
                 {
                   advertiser_amount: -2.925, (advertiser_amount = offer_discount * bid ==> -90*0.0325= 2.935)
                   publisher_amount: 1.7155125,  (publisher_amount = {advertiser_amount - share_network_costs - net_of_costs} * rev_share ==> {2.925 - 0.43875} * 0.69 = 1.7155125)
                   tapjoy_amount: 1.2094875,  (tapjoy_amount =  advertiser_amount - publisher_amount ==> 2.925 - 1.7155125 = 1.2094875)
                   spend_share: 0.5865, (spend_share =  publisher_amount / advertiser amount ==> 1.7155125 / 2.925 = 0.5865)
                   share_network_costs: 0.43875, (share_network_costs = advertiser_amount * % of network_fee ==> 2.925 * 0.15 = 0.43875)
                   share_tapjoy_share: 0.7707375 (share_tapjoy_share = tapjoy_amount - share_network_costs ==> 1.2094875 - 0.43875 = 0.7707375 )
               }
               end
               assert_convert_offer!
             end
=end
module RevshareHelper
  def assert_convert_offer!(params = {})
    publisher_partner = TestChamber::Partner.new(rev_share: rev_share/100.0,
                         max_deduction_percentage: max_deduction_percentage,
                         reseller_id: reseller ? reseller.id : nil,
                         ignore_cache: ignore_cache)

    publisher_app = TestChamber::App.new(partner_id: publisher_partner.id,
                   apps_network_id: kakao_app ? kakao_network_id : nil,
                   rev_share_override: rev_share_override,
                   ignore_cache: ignore_cache)


    advertiser_partner = TestChamber::Partner.new(id: params[:pub_eq_advertiser] ? publisher_partner.id : nil,
                          offer_discount: offer_discount,
                          discount_all_offer_types: true,
                          reseller_id: reseller ? reseller.id : nil,
                          ignore_cache: ignore_cache)

    offer = described_class.new(bid: bid, store_name: store, partner_id: advertiser_partner.id)
    add_context(device_id: TestChamber.current_device.udid,
                offer: offer,
                publisher_partner: publisher_partner,
                advertiser_partner: advertiser_partner)

    # TestChamber::OptSOA.set_top_offers([offer.id])
    publisher_app.click_offer(offer)
    conversion = publisher_app.convert_offer(offer)

    add_context(conversion: conversion)

    actual_amounts = conversion.rev_share_amounts

    # The column in the mysql db for Conversion.spend_share is a float so it is sometimes inaccurate.
    # This is apparently not an actual problem because we don't use this field so we are rounding it here
    actual_amounts[:spend_share] = actual_amounts[:spend_share].round(3) if actual_amounts[:spend_share]
    actual_amounts
  end
end

shared_context "Revshare test configuration" do
  include_context "I am logged in"
  include_context "using the new look"

  let(:kakao_app) { false }
  let(:max_deduction_percentage) { 1.0 }
  let(:offer_discount) { nil }
  let(:reseller_id) { nil }
  let(:rev_share_override) { nil }
  let(:ignore_cache) { true }
  let(:store) { '' }
  let(:reseller) { nil }
end

shared_context "50% revshare" do
  include_context "Revshare test configuration"
  let(:rev_share) { 50 }
end

shared_context "60% revshare" do
  include_context "Revshare test configuration"
  let(:rev_share) { 60 }
end

shared_context "70% revshare" do
  include_context "Revshare test configuration"
  let(:rev_share) { 70 }
end

shared_examples "assert convert offer!" do
  include RevshareHelper
  it "creates a #{described_class.name} and converts it" do
    expect(assert_convert_offer!).to eq(expected_amounts)
  end
end

shared_examples "assert convert offer! where publisher equals advertiser" do
  include RevshareHelper
  it "creates a #{described_class.name} and converts it" do
    expect(assert_convert_offer!(pub_eq_advertiser: true)).to eq(expected_amounts)
  end
end

shared_examples "revshare at 50% with no offer discount" do
  include_context "50% revshare"
  let(:offer_discount) { nil }

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

  context "when store is skt" do
    let(:store) { 'skt' }

    context "with a $2.0 bid" do
      let(:bid) { 2.0 }
      let(:expected_amounts) do
        {
          advertiser_amount: -200.0,
          publisher_amount: 72.6,
          tapjoy_amount: 107.6,
          spend_share: 0.363,
          share_net_of_costs: 19.8,
          share_network_costs: 35.0,
          share_tapjoy_share: 72.6,
        }
      end
      it_validates "assert convert offer!"
    end
  end

  context "when store is google" do
    let(:store) { 'google' }

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

shared_examples "revshare at 50% with 10% offer discount" do
  include_context "50% revshare"
  let(:offer_discount) { 10 }

  context "with a $2.0 bid" do
    let(:bid) { 2.0 }
    let(:expected_amounts) do
      {
        advertiser_amount: -180.0,
        publisher_amount: 74.25,
        tapjoy_amount: 105.75,
        spend_share: 0.413,
        share_network_costs: 31.5,
        share_tapjoy_share: 74.25
      }
    end
    it_validates "assert convert offer!"
  end
end

shared_examples "revshare at 50% with 15% offer discount" do
  include_context "50% revshare"
  let(:offer_discount) { 15 }

  context "with a $2.0 bid" do
    let(:bid) { 2.0 }
    let(:expected_amounts) do
      {
        advertiser_amount: -170.0,
        publisher_amount: 70.125,
        tapjoy_amount: 99.875,
        spend_share: 0.413,
        share_network_costs: 29.75,
        share_tapjoy_share: 70.125
      }
    end
    it_validates "assert convert offer!"
  end

  context "when store is gfan" do
    let(:store) { 'gfan' }

    context "when a $2.0 bid" do
      let(:bid) { 2.0 }
      let(:expected_amounts) do
        {
          advertiser_amount: -170.0,
          publisher_amount: 70.125,
          tapjoy_amount: 99.875,
          spend_share: 0.413,
          share_network_costs: 29.75,
          share_tapjoy_share: 70.125
        }
      end
      it_validates "assert convert offer!"
    end
  end
end

shared_examples "revshare at 60% with no offer discount" do
  include_context "60% revshare"
  let(:offer_discount) { nil }

  context "with a $0.02 bid" do
    let(:bid) { 0.02 }
    let(:expected_amounts) do
      {
        advertiser_amount: -2.0,
        publisher_amount: 0.99,
        tapjoy_amount: 1.01,
        spend_share: 0.495,
        share_network_costs: 0.35,
        share_tapjoy_share: 0.66
      }
    end
    it_validates "assert convert offer!"
  end

  context "with a $0.015 bid" do
    let(:bid) { 0.015 }
    let(:expected_amounts) do
      {
        advertiser_amount: -1.5,
        publisher_amount: 0.743,
        tapjoy_amount: 0.757,
        spend_share: 0.495,
        share_network_costs: 0.263,
        share_tapjoy_share: 0.494
      }
    end
    it_validates "assert convert offer!"
  end

  context "with a $0.00525 bid" do
    let(:bid) { 0.00525 }
    let(:expected_amounts) do
      {
        advertiser_amount: -0.525,
        publisher_amount: 0.26,
        tapjoy_amount: 0.265,
        spend_share: 0.495,
        share_network_costs: 0.092,
        share_tapjoy_share:0.173
      }
    end
    it_validates "assert convert offer!"
  end
end

shared_examples "signed up by a reseller at 60% revshare" do
  include_context "60% revshare"
  let(:offer_discount) { nil }
  let(:ignore_cache) { true }

  context "40% reseller rev share" do
    let(:reseller) { TestChamber::Reseller.new(reseller_rev_share: 0.40) }

    context "with a $2.0 bid" do
      let(:bid) { 2.0 }
      let(:expected_amounts) do
        {
          advertiser_amount: -200.0,
          publisher_amount: 66.0,
          tapjoy_amount: 134.0,
          spend_share: 0.33,
          share_network_costs: 35.0,
          share_tapjoy_share: 99.0
        }
      end
      it_validates "assert convert offer!"
    end

    context "with a $0.035 bid" do
      let(:bid) { 0.035 }
      let(:expected_amounts) do
        {
          advertiser_amount: -3.5,
          publisher_amount: 1.155,
          tapjoy_amount: 2.345,
          spend_share: 0.33,
          share_network_costs: 0.613,
          share_tapjoy_share: 1.732
        }
      end
      it_validates "assert convert offer!"
    end
  end

  context "90% reseller rev share" do
    let(:reseller) { TestChamber::Reseller.new(reseller_rev_share: 0.90) }

    context "with a $2.0 bid" do
      let(:bid) { 2.0 }
      let(:expected_amounts) do
        {
          advertiser_amount: -200.0,
          publisher_amount: 148.5,
          tapjoy_amount: 51.5,
          spend_share: 0.743,
          share_network_costs: 35.0,
          share_tapjoy_share: 16.5
        }
      end
      it_validates "assert convert offer!"
    end

    context "with a $0.035 bid" do
      let(:bid) { 0.035 }
      let(:expected_amounts) do
        {
          advertiser_amount: -3.5,
          publisher_amount: 2.599,
          tapjoy_amount: 0.901,
          spend_share: 0.743,
          share_network_costs: 0.613,
          share_tapjoy_share: 0.288
        }
      end
      it_validates "assert convert offer!"
    end
  end
end

shared_examples "revshare at 60% with 10% offer discount" do
  include_context "60% revshare"
  let(:offer_discount) { 10 }

  context "with a $0.02 bid" do
    let(:bid) { 0.02 }
    let(:expected_amounts) do
      {
        advertiser_amount: -1.8,
        publisher_amount: 0.891,
        tapjoy_amount: 0.909,
        spend_share: 0.495,
        share_network_costs: 0.315,
        share_tapjoy_share: 0.594
      }
    end
    it_validates "assert convert offer!"
  end

  context "with a $0.015 bid" do
    let(:bid) { 0.015 }
    let(:expected_amounts) do
      {
        advertiser_amount: -1.35,
        publisher_amount: 0.668,
        tapjoy_amount: 0.682,
        spend_share: 0.495,
        share_network_costs: 0.236,
        share_tapjoy_share: 0.446
      }
    end
    it_validates "assert convert offer!"
  end

  # TODO check math on this one
  context "with a $0.00525 bid" do
    let(:bid) { 0.00525 }
    let(:expected_amounts) do
      {
        advertiser_amount: -0.473,
        publisher_amount: 0.234,
        tapjoy_amount: 0.239,
        spend_share: 0.495,
        share_network_costs: 0.083,
        share_tapjoy_share: 0.156
      }
    end
    it_validates "assert convert offer!"
  end
end

shared_examples "revshare at 60% and store is skt" do
  include_context "60% revshare"
  let(:offer_discount) { 10 }
  let(:store) { 'skt' }

  context "with a $2.0 bid" do
    let(:bid) { 2.0 }
    let(:expected_amounts) do
      {
        advertiser_amount: -180.0,
        publisher_amount: 78.408,
        tapjoy_amount: 83.772,
        spend_share: 0.436,
        share_net_of_costs: 17.82,
        share_network_costs: 31.5,
        share_tapjoy_share: 52.272,
      }
    end
    it_validates "assert convert offer!"
  end

  context "with a $0.015 bid" do
    let(:bid) { 0.015 }
    let(:expected_amounts) do
      {
        advertiser_amount: -1.35,
        publisher_amount: 0.588,
        tapjoy_amount: 0.628,
        spend_share: 0.436,
        share_net_of_costs: 0.134,
        share_network_costs: 0.236,
        share_tapjoy_share: 0.392
      }
    end
    it_validates "assert convert offer!"
  end

  context "with a $0.00525 bid" do
    let(:bid) { 0.00525 }
    let(:expected_amounts) do
      {
        advertiser_amount: -0.473,
        publisher_amount: 0.206,
        tapjoy_amount: 0.22,
        spend_share: 0.436,
        share_net_of_costs: 0.047,
        share_network_costs: 0.083,
        share_tapjoy_share: 0.137
      }
    end
    it_validates "assert convert offer!"
  end
end

shared_examples "revshare at 60% with 15% offer discount" do
  include_context "60% revshare"
  let(:offer_discount) { 15 }

  context "with a $0.02 bid" do
    let(:bid) { 0.02 }
    let(:expected_amounts) do
      {
        advertiser_amount: -1.7,
        publisher_amount: 0.842,
        tapjoy_amount: 0.858,
        spend_share: 0.495,
        share_network_costs: 0.298,
        share_tapjoy_share: 0.56
      }
    end
    it_validates "assert convert offer!"
  end

  context "with a $0.015 bid" do
    let(:bid) { 0.015 }
    let(:expected_amounts) do
      {
        advertiser_amount: -1.275,
        publisher_amount: 0.631,
        tapjoy_amount: 0.644,
        spend_share: 0.495,
        share_network_costs: 0.223,
        share_tapjoy_share: 0.421
      }
    end
    it_validates "assert convert offer!"
  end

  # check math. Tapjoy_amount and publisher_amount used to be the same, now they are different
  context "with a $0.00525 bid" do
    let(:bid) { 0.00525 }
    let(:expected_amounts) do
      {
        advertiser_amount: -0.446,
        publisher_amount: 0.221,
        tapjoy_amount: 0.225,
        spend_share: 0.496,
        share_network_costs: 0.078,
        share_tapjoy_share: 0.147
      }
    end
    it_validates "assert convert offer!"
  end
end

shared_examples "publisher equals advertiser at 60% revshare with 15% offer discount" do
  include_context "60% revshare"
  let(:offer_discount) { 15 }
  # when advertiser == publisher, no revshare should be paid.
  context "with a $2.0 bid" do
    let(:bid) { 2.0 }
    let(:expected_amounts) do
      {
        advertiser_amount: 0.0,
        publisher_amount: 0.0,
        tapjoy_amount: 0.0,
        spend_share: 0.0,
      }
    end
    it_validates "assert convert offer! where publisher equals advertiser"
  end

  context "with a $0.00525 bid" do
    let(:bid) { 0.00525 }
    let(:expected_amounts) do
      {
        advertiser_amount: 0.0,
        publisher_amount: 0.0,
        tapjoy_amount: 0.0,
        spend_share: 0.0,
      }
    end
    it_validates "assert convert offer! where publisher equals advertiser"
  end
end

  # rev share override actually means:
  # the currency's rev share (if set) overrides
  # the publisher's set rev share
shared_examples "rev share override at 60% revshare" do
  include_context "60% revshare"
  let(:offer_discount) { 15 }

  context "with a $2 bid" do
    let(:bid) { 2.0 }

    context "with a 90% rev share override" do
      let(:rev_share_override) { 0.90 }
      let(:expected_amounts) do
        {
          advertiser_amount: -170.0,
          publisher_amount: 126.225,
          tapjoy_amount: 43.775,
          spend_share: 0.742,
          share_network_costs: 29.75,
          share_tapjoy_share: 14.025
        }
      end
      it_validates "assert convert offer!"
    end

    context "with a 20% rev share override" do
      let(:rev_share_override) { 0.20 }
      let(:expected_amounts) do
        {
          advertiser_amount: -170.0,
          publisher_amount: 28.05,
          tapjoy_amount: 141.95,
          spend_share: 0.165,
          share_network_costs: 29.75,
          share_tapjoy_share: 112.2
        }
      end
      it_validates "assert convert offer!"
    end
  end

  context "with a $0.015 bid" do
    let(:bid) { 0.015 }

    context "with a 90% rev share override" do
      let(:rev_share_override) { 0.90 }
      let(:expected_amounts) do
        {
          advertiser_amount: -1.275,
          publisher_amount: 0.947,
          tapjoy_amount: 0.328,
          spend_share: 0.743,
          share_network_costs: 0.223,
          share_tapjoy_share: 0.105
        }
      end
      it_validates "assert convert offer!"
    end

    context "with a 20% rev share override" do
      let(:rev_share_override) { 0.20 }
      let(:expected_amounts) do
        {
          advertiser_amount: -1.275,
          publisher_amount: 0.21,
          tapjoy_amount: 1.065,
          spend_share: 0.165,
          share_network_costs: 0.223,
          share_tapjoy_share: 0.842
        }
      end
      it_validates "assert convert offer!"
    end
  end
end

shared_examples "revshare at 70% with no offer discount" do
  include_context "70% revshare"
  let(:offer_discount) { nil }

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

shared_examples "revshare at 70% with 10% offer discount" do
  include_context "70% revshare"
  let(:offer_discount) { 10 }

  context "with a $100 bid" do
    let(:bid) { 100.0 }
    let(:expected_amounts) do
      {
        advertiser_amount: -9000.0,
        publisher_amount: 5197.5,
        tapjoy_amount: 3802.5,
        spend_share: 0.578,
        share_network_costs: 1575.0,
        share_tapjoy_share: 2227.5
      }
    end
    it_validates "assert convert offer!"
  end

  # Kakao revshares are calculated differently than normal. The Kakao
  # percentage is calculated off the payment amount, not based on the
  # amount after network costs. Revenue Share is calculated off of
  # this remainder.
  context "when kakao app" do
    let(:kakao_app) { true }
    let(:kakao_network_id) {'3bfbf491-024a-46b4-a6ed-43f859291765'}

    context "with a $2.0 bid" do
      let(:bid) { 2.0 }
      let(:expected_amounts) do
        {
          advertiser_amount: -180.0,
          publisher_amount: 81.9,
          tapjoy_amount: 66.6,
          spend_share: 0.455,
          share_net_of_costs: 31.5,
          share_network_costs: 31.5,
          share_tapjoy_share: 35.1
        }
      end
      it_validates "assert convert offer!"
    end

    context "with a $0.015 bid" do
      let(:bid) { 0.015 }
      let(:expected_amounts) do
        {
          advertiser_amount: -1.350,
          publisher_amount: 0.614,
          tapjoy_amount: 0.5,
          spend_share: 0.455,
          share_net_of_costs: 0.236,
          share_network_costs: 0.236,
          share_tapjoy_share: 0.264
        }
      end
      it_validates "assert convert offer!"
    end

    context "with a $0.00525 bid" do
      let(:bid) { 0.00525}
      let(:expected_amounts) do
        {
          advertiser_amount: -0.473,
          publisher_amount: 0.215,
          tapjoy_amount: 0.175,
          spend_share: 0.455,
          share_net_of_costs: 0.083,
          share_network_costs: 0.083,
          share_tapjoy_share: 0.092
        }
      end
      it_validates "assert convert offer!"
    end
  end
end

shared_examples "max deductions at 70% revshare" do
  include_context "70% revshare"
  let(:offer_discount) { 10 }

  context "with a max deduction percentage of 5%" do
    let(:max_deduction_percentage) { 0.05 }

    context "with a $0.035 bid" do
      let(:bid) { 0.035 }
      let(:expected_amounts) do
        {
          advertiser_amount: -3.150,
          publisher_amount: 2.095,
          tapjoy_amount: 1.055,
          spend_share: 0.665,
          share_network_costs: 0.158,
          share_tapjoy_share: 0.897
        }
      end
      it_validates "assert convert offer!"
    end

    context "with a $2.0 bid" do
      let(:bid) { 2.0 }
      let(:expected_amounts) do
        {
          advertiser_amount: -180.0,
          publisher_amount: 119.7,
          tapjoy_amount: 60.3,
          spend_share: 0.665,
          share_network_costs: 9.0,
          share_tapjoy_share: 51.3
        }
      end
      it_validates "assert convert offer!"
    end
  end

  context "with a max deduction percentage of 10%" do
    let(:max_deduction_percentage) { 0.10 }

    context "with a $0.035 bid" do
      let(:bid) { 0.0325 }
      let(:expected_amounts) do
        {
          advertiser_amount: -2.925,
          publisher_amount: 1.843,
          tapjoy_amount: 1.082,
          spend_share: 0.63,
          share_network_costs: 0.293,
          share_tapjoy_share: 0.789
        }
      end
      it_validates "assert convert offer!"
    end

    context "with a $2.0 bid" do
      let(:bid) { 2.0 }
      let(:expected_amounts) do
        {
          advertiser_amount: -180.0,
          publisher_amount: 113.4,
          tapjoy_amount: 66.6,
          spend_share: 0.630,
          share_network_costs: 18.0,
          share_tapjoy_share: 48.6
        }
      end
      it_validates "assert convert offer!"
    end
  end
end

# assert_convert_offer! called 1 time
shared_examples "revshare at 70% with 15% offer discount" do
  include_context "70% revshare"
  let(:offer_discount) { 15 }

  context "with a $100 bid" do
    let(:bid) { 100.0 }
    let(:expected_amounts) do
      {
        advertiser_amount: -8500.0,
        publisher_amount: 4908.75,
        tapjoy_amount: 3591.25,
        spend_share: 0.578,
        share_network_costs: 1487.5,
        share_tapjoy_share: 2103.75
      }
    end
    it_validates "assert convert offer!"
  end
end

# assert_convert_offer! called 1 time
shared_examples "revshare at 70% with 30% offer discount" do
  include_context "70% revshare"
  let(:offer_discount) { 30 }

  context "when store is skt" do
    let(:store) { 'skt' }

    context "with a $2.0 bid" do
      let(:bid) { 2.0 }
      let(:expected_amounts) do
        {
          advertiser_amount: -140.0,
          publisher_amount: 71.148,
          tapjoy_amount: 54.992,
          spend_share: 0.508,
          share_net_of_costs: 13.86,
          share_network_costs: 24.5,
          share_tapjoy_share: 30.492
        }
      end
      it_validates "assert convert offer!"
    end
  end
end
