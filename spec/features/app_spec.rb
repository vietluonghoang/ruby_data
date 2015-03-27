require 'spec_helper'

creation_methods = [:api, :ui_v1, :ui_v2]

creation_methods.each do |create_with|
  describe "TestChamber::App creation with #{create_with}", :type => :feature do
    include_context "I am logged in"
    include_context "using the new look"

    context "when created by the default partner" do
      let(:app) { TestChamber::App.new(:create_with => create_with) }
      it "has a UUID" do
        expect(app.id).to be_a_uuid
      end
    end

    context "when created by a specific partner" do
      let(:partner) { TestChamber::Partner.new }
      let(:app) { TestChamber::App.new :partner_id => partner.id }
      it "stores partner id" do
        expect(app.partner_id).to eql partner.id
        expect(app.partner_id).to eql TestChamber::Models::App.find(app.id).partner_id
      end
    end

    context "when it belongs to an apps network" do
      # An App can belong to an 'Apps Network'. This controls things like revshare,
      # and blacklists. Some of these are actual networks (Kakao), others are merely
      # groupings that we use to control blacklists (like Disney apps).
      let(:apps_network_id) {'3bfbf491-024a-46b4-a6ed-43f859291765'} # Kakao id
      let(:app) { TestChamber::App.new :apps_network_id => apps_network_id }
      it "belongs to the right apps network" do
        mapping = TestChamber::Models::AppAppsNetworkMapping.where(:app_id => app.id).first
        expect(mapping.apps_network_id).to eql '3bfbf491-024a-46b4-a6ed-43f859291765'
      end
    end
  end
end
