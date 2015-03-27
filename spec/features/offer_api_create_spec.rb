require 'spec_helper'


[#TestChamber::Offer::Reconnect,
  #TestChamber::Offer::Engagement,
 TestChamber::Offer::Video,
 #TestChamber::Offer::Install, # Install is created with :all creator, not :api, no response_code is available
 ].each do |offer_type|
  describe offer_type do
    include_context "I am logged in"
    let(:offer) do
      described_class.new(create_with: :api)
    end

    context "Add new #{offer_type} via api" do
      it "Add new offer via api" do
        expect(offer.response_code).to eql(200)
        expect(offer.id).to be_a_uuid
      end
    end
  end
end
