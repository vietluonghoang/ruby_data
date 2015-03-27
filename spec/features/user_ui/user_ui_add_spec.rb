require 'spec_helper'

describe TestChamber::UserUI do

  let(:is_super_user) { false }
  let(:email_address) { nil }
  let(:time_zone) { "(GMT-10:00) Hawaii" }
  let(:country) { "Viet Nam" }

  let(:user_ui) do
    TestChamber::UserUI.new(
      :is_super_user => is_super_user,
      :email_address => email_address,
      :time_zone => time_zone,
      :country => country,
    )
  end

  {
    "aaaa" => TestChamber::UserUI.error_message[:error_field_is_required],
    " " => TestChamber::UserUI.error_message[:error_field_is_required],
    "       " => TestChamber::UserUI.error_message[:error_field_is_required],
    "helloguys" => TestChamber::UserUI.error_message[:error_field_is_required],
    "   @a.an" => TestChamber::UserUI.error_message[:error_field_is_required],
    "   @   .com" => TestChamber::UserUI.error_message[:error_field_is_required],
    "   @   . " => TestChamber::UserUI.error_message[:error_field_is_required],
    "   @test. " => TestChamber::UserUI.error_message[:error_field_is_required],
    "helloguys@test. " => TestChamber::UserUI.error_message[:error_field_is_required],
    "helloguys@   .com" => TestChamber::UserUI.error_message[:error_field_is_required],
    "helloguys@test" => TestChamber::UserUI.error_message[:error_should_look_like_email_address],
    "helloguys.com" => TestChamber::UserUI.error_message[:error_field_is_required],
    "helloguys@blahblah@test.com" => TestChamber::UserUI.error_message[:error_field_is_required],
    "helloguys@test.com@" => TestChamber::UserUI.error_message[:error_field_is_required],
    "@helloguys@test.com" => TestChamber::UserUI.error_message[:error_field_is_required],
    "helloguys@test..com" => TestChamber::UserUI.error_message[:error_field_is_required],
    "helloguys@.com" => TestChamber::UserUI.error_message[:error_field_is_required],
    "helloguys.@com" => TestChamber::UserUI.error_message[:error_should_look_like_email_address],
    "helloguys@.test.com" => TestChamber::UserUI.error_message[:error_field_is_required],
    "hello.guys@com" => TestChamber::UserUI.error_message[:error_should_look_like_email_address],
    "hello.guys.com" => TestChamber::UserUI.error_message[:error_field_is_required],
    "helloguys@test.c" => TestChamber::UserUI.error_message[:error_should_look_like_email_address],
    "helloguys@test.comcom" => TestChamber::UserUI.error_message[:error_should_look_like_email_address],
    "~!@#^&*()_+{}|:<>?@*^$.&*$^&^!" => TestChamber::UserUI.error_message[:error_field_is_required],
    "hello!#%^&*@gmail.com" => TestChamber::UserUI.error_message[:error_should_look_like_email_address],
    "sgs1 234@sgs.com" => TestChamber::UserUI.error_message[:error_field_is_required],
  }.each do |email, error_message|
    context "when adding user with an invalid email address '#{email}' its error should be #{error_message}" do
      let(:email_address) { email }

      it "has error_message" do
        user_ui.create!
        expect(user_ui.messages[:email_error]).to include error_message
      end
    end
  end

  normal_user_email = "sgsTestAdd1#{Time.now.strftime('%Y%m%d%H%M%S%L')}@testt.com"
  context "When creating new normal user with valid email address '#{normal_user_email}'" do
    let(:email_address) { normal_user_email }

    it "creates a normal user successfully" do
      user_ui.create!
      expect(user_ui.messages[:flash_message]).to include TestChamber::UserUI.error_message[:create_user_success_message_register]
    end
  end

  context "When creating new normal user with invalid time zone and country" do
    let(:email_address) { "sgsTestAdd2#{Time.now.strftime('%Y%m%d%H%M%S%L')}@testt.com" }
    let(:time_zone) { nil }
    let(:country) { nil }

    it "has error_message" do
      user_ui.create!
      expect(user_ui.messages[:time_zone_error]).to include TestChamber::UserUI.error_message[:error_field_is_required]
      expect(user_ui.messages[:country_error]).to include TestChamber::UserUI.error_message[:error_field_is_required]
    end
  end

  taken_user_email = "sgsTestAdd3#{Time.now.strftime('%Y%m%d%H%M%S%L')}@testt.com"
  context "check taken email: #{taken_user_email}" do
    let(:email_address) { taken_user_email }

    it "has error_message: #{TestChamber::UserUI.error_message[:error_email_has_been_taken]}" do
      user_ui.create!
      user_ui.create!
      expect(user_ui.messages[:email_error]).to include TestChamber::UserUI.error_message[:error_email_has_been_taken]
    end
  end

end
