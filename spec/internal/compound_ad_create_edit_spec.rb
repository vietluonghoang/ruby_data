require 'spec_helper'

# currently the only combination that works for compound offers is Video created with api and edited with ui_v1
describe "TestChamber::Offer::Video creation" do

  context "with no compound_template_url" do
    let(:offer) { TC::Offer::Video.new(create_with: :api, edit_with: :ui_v1) }

    it "should not have a value for compound_template_url" do
      expect(offer.compound_template_url).to be_nil
    end

    it "should have a value for compound_template_url after edit with ui_v1" do
      offer.edit(edit_with: :ui_v1, compound_template_url: 'someurl')
      expect(offer.compound_template_url).to eq('someurl') 

      offer_from_db = TC::Offer::Video.new(id: offer.id)
      expect(offer_from_db.compound_template_url).to eq('someurl') 
    end
  end
end
