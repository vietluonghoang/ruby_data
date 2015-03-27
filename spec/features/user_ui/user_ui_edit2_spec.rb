#
# UserUI edit spec is split across 2 files to be more optimally run by parallel_tests.
#

require 'spec_helper'

describe TestChamber::UserUI do
  include_context "User UI edit configuration"

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
    "hello!#%^&*@gmail.com" => TestChamber::UserUI.error_message[:error_email_has_special_character],
    "sgs1 234@sgs.com" => TestChamber::UserUI.error_message[:error_field_is_required],
  }.each do |change_email, change_email_message|
    context "when inputing email address '#{change_email}' its message should be '#{change_email_message}'" do
      let(:email_address) { change_email }

      it "has error_message" do
        user_ui.update!
        expect(user_ui.messages[:email_error]).to include change_email_message
      end
    end
  end

  {
    "sgsTestEdit1#{Time.now.strftime('%Y%m%d%H%M%S%L')}@tapjoy.com" => TestChamber::UserUI.error_message[:update_success_message]
  }.each do |change_email, message|
    context "when inputing email address '#{change_email}' its message should be #{message}" do
      let(:email_address) { change_email }
      it "has error_message" do
        user_ui.update!
        expect(user_ui.messages[:flash_message]).to include message
      end
      # upon successfully updating email (username) the session is invalidated
      # log back in
      after do
        ENV['TEST_USERNAME'] = email_address
        ENV['TEST_PASSWORD'] = confirm_password
        TestChamber.user_cookies = nil
        Capybara.page.driver.browser.manage.delete_all_cookies
        login_test_user
      end
    end

    [
      {
        :change_password => "~!@^&*()_+{}|:<>?@*^$.&*$^&^!",
        :change_confirmation_password => "~!@^&*()_+{}|:<>?@*^$.&*$^&^!",
        :change_password_error => nil,
        :change_confirmation_password_error => nil,
        :update_success_message => TestChamber::UserUI.error_message[:update_success_message]
      },
      {
        :change_password => "1234",
        :change_confirmation_password => "1234",
        :change_password_error => nil,
        :change_confirmation_password_error => nil,
        :update_success_message => TestChamber::UserUI.error_message[:update_success_message]
      },
      {
        :change_password => ENV["TEST_PASSWORD"],
        :change_confirmation_password => ENV["TEST_PASSWORD"],
        :change_password_error => nil,
        :change_confirmation_password_error => nil,
        :update_success_message => TestChamber::UserUI.error_message[:update_success_message]
      }
    ].each do |input|
      context "when inputing new password '#{input[:change_password]}' and confirmation pass '#{input[:change_confirmation_password]}' its error should be '#{input[:change_password_error]}' and '#{input[:change_confirmation_password_error]}'" do
        let(:password) { input[:change_password] }
        let(:confirm_password) { input[:change_confirmation_password] }

        xit "has error_message" do
          user_ui.update!
          expect(user_ui.messages[:password_error]).to eql input[:change_password_error]
          expect(user_ui.messages[:confirm_password_error]).to eql input[:change_confirmation_password_error]
          expect(user_ui.messages[:flash_message]).to include input[:update_success_message]
        end
      end
    end
  end
end
