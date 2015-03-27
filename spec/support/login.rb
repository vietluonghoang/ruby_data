shared_context "I am logged in" do

  def login
    Capybara.using_driver :selenium do
      TestChamber::Dashboard.new.login
    end
  end

  before :all do
    login
  end

  before :each do
    login
  end
end

shared_context "I am logged out" do
  let(:dashboard) { TestChamber::Dashboard.new }

  before do
    dashboard.logout
  end
end
