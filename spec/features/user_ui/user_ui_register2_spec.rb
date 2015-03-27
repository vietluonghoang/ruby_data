#
# UserUI register spec is split across 2 files to be more optimally run by parallel_tests.
#

require 'spec_helper'

describe TestChamber::UserUI do
  include_context "User UI register configuration"
  super_user_email = "sgsTestRegister1#{Time.now.strftime('%Y%m%d%H%M%S%L')}@testt.com"

  context "When creating new super user with valid email address '#{super_user_email}'" do
    let(:is_super_user) { true }
    let(:email_address) { super_user_email }

    xit "creates a super user successfully" do
      user_ui.create!

      # Since there is no success message that displays after successfully registering. We using the email address
      # that is displayed at the top right corner of the page to determine if the registration progress finishes
      # successfully or not.

      expect(user_ui.create_account_success).to eql super_user_email
    end
  end

  {
    "aaaa" => TestChamber::UserUI.error_message[:error_email_too_short],
    " " => TestChamber::UserUI.error_message[:error_email_too_short],
    "       " => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "   @a.an" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "   @   .com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "   @   . " => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "   @test. " => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys@test. " => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys@   .com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys@test" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys.com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys@blahblah@test.com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys@test.com@" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "@helloguys@test.com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys@test..com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys@.com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys.@com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys@.test.com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "hello.guys@com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "hello.guys.com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys@test.c" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "helloguys@test.comcom" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "~!@#^&*()_+{}|:<>?@*^$.&*$^&^!" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "hello!#%^&*@gmail.com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    "sgs1 234@sgs.com" => TestChamber::UserUI.error_message[:error_should_look_like_an_email_address],
    super_user_email => TestChamber::UserUI.error_message[:error_email_has_already_been_taken],
  }.each do |email,  error_message|
    context "When creating new super user with valid email address '#{email}' its error should be #{error_message}" do
      let(:is_super_user) { true }
      let(:email_address) { email }

      xit "has error_message" do
        user_ui.create!
        expect(user_ui.messages[:email_error]).to eql error_message
      end
    end
  end

  {
    "" => TestChamber::UserUI.error_message[:error_cant_blank],
    "   " => TestChamber::UserUI.error_message[:error_cant_blank]
  }.each do |input, error_message|
    context "When inputting Company Name with '#{input}'" do
      let(:email_address) { super_user_email }
      let(:company_name) { input }

      xit "has error_message" do
        user_ui.create!
        expect(user_ui.messages[:partner_name_error]).to eql error_message
      end
    end
  end

  context "When not inputting Time Zone" do
    let(:email_address) { super_user_email }
    let(:time_zone) { nil }

    xit "has error_message" do
      user_ui.create!
      expect(user_ui.messages[:time_zone_error]).to eql TestChamber::UserUI.error_message[:error_cant_blank]
    end
  end

  context "When do not check Agree Term of Service" do
    let(:email){ "sgsTestRegister3#{Time.now.strftime('%Y%m%d%H%M%S%L')}@testt.com" }
    let(:email_address) { email }
    let(:agree_terms_of_service) { false }

    xit "has error_message" do
      user_ui.create!
      expect(user_ui.messages[:is_accept_tos_checked]).to include TestChamber::UserUI.error_message[:tos_is_not_checked]
    end
  end
end
