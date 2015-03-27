shared_context "User UI edit configuration" do
  include_context "I am logged in"
  include_context "using the new look"

  let(:email_address) { nil }
  let(:password) { "m00ncak3" }
  let(:confirm_password) { "m00ncak3" }
  let(:company_name) { "SGS" }
  let(:time_zone) { "(GMT-10:00) Hawaii" }
  let(:language) { "English" }
  let(:receive_campaign_emails) { false }
  let(:country) { "Germany" }
  let(:is_advertiser) { true }
  let(:is_publisher) { true }
  let(:agree_terms_of_service) { true }

  let(:user_ui) do
    TestChamber::UserUI.new(
      :email_address => email_address,
      :password => password,
      :confirm_password => confirm_password,
      :time_zone => time_zone,
      :country => country,
      :language => language,
      :receive_campaign_emails => receive_campaign_emails,
      :company_name => company_name,
      :is_advertiser => is_advertiser,
      :is_publisher => is_publisher,
      :agree_terms_of_service => agree_terms_of_service
    )
  end
end

shared_context "User UI register configuration" do
  include_context "I am logged in"
  include_context "using the new look"

  let(:is_super_user) { true }
  let(:email_address) { nil }
  let(:company_name) { "SGS" }
  let(:password) { "m00ncak3" }
  let(:confirm_password) { "m00ncak3" }
  let(:time_zone) { "(GMT-11:00) Samoa" }
  let(:country) { "Viet Nam" }
  let(:language) { "English" }
  let(:is_advertiser) { true }
  let(:is_publisher) { true }
  let(:agree_terms_of_service) { true }
  let(:receive_campaign_emails) { false }

  let(:user_ui) do
    TestChamber::UserUI.new(
      :is_super_user => is_super_user,
      :email_address => email_address,
      :password => password,
      :confirm_password => confirm_password,
      :time_zone => time_zone,
      :country => country,
      :language => language,
      :receive_campaign_emails => receive_campaign_emails,
      :company_name => company_name,
      :is_advertiser => is_advertiser,
      :is_publisher => is_publisher,
      :agree_terms_of_service => agree_terms_of_service
    )
  end
end
