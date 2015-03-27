require 'spec_helper'

describe 'Compound ad unit' do
  FIXTURES_DIR = 'spec/fixtures/compound'

  context 'with single image module', :appium do
    let(:single_image_fixture) { JSON.parse File.read(File.join(FIXTURES_DIR, 'end_card.json')) }

    before(:each) do
      Capybara.using_driver :selenium do
        @offer = TestChamber::Offer::Video.new(create_with: :api, edit_with: :ui_v1,
                                               bid: 1.00)
        @offer.edit(compound_template_url: single_image_fixture['template_url'])
        @app = TestChamber::App.new
      end
    end

    it 'converts the module' do
      TestChamber::OptSOA.set_top_offers([@offer.id], device_id: :all)
      offerwall = @app.offerwall
      offerwall.click_offer(@offer.id).convert!
    end
  end
end
