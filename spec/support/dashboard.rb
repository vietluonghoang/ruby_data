shared_context "using the new look" do
  let(:dashboard) { TestChamber::Dashboard.new }
  
  before do
    dashboard.use_new_look
  end
end
