#
# UserUI register spec is split across 2 files to be more optimally run by parallel_tests.
#

require 'spec_helper'

describe TestChamber::UserUI do
  include_context "User UI register configuration"

  [
    {
      :change_password => "abcd",
      :change_confirmation_password => "dcba",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "abc",
      :change_confirmation_password => "dcba",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "dcba",
      :change_confirmation_password => "abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "dcba",
      :change_confirmation_password => "",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "",
      :change_confirmation_password => "dcba",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "dcba",
      :change_confirmation_password => "",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "",
      :change_confirmation_password => "abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "abc",
      :change_confirmation_password => "",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "a bc de",
      :change_confirmation_password => "a d e  fg",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "a bc de",
      :change_confirmation_password => "abcde",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "a bc de",
      :change_confirmation_password => "abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "a bc de",
      :change_confirmation_password => "abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "a bc de",
      :change_confirmation_password => "",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "abcde",
      :change_confirmation_password => "a bc de",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "abcde",
      :change_confirmation_password => "a bc de",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "abc",
      :change_confirmation_password => "a bc de",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "",
      :change_confirmation_password => "a bc de",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => " abcd",
      :change_confirmation_password => "abcd",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "    ",
      :change_confirmation_password => "abcd",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "    ",
      :change_confirmation_password => "abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "   ",
      :change_confirmation_password => "abcd",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "   ",
      :change_confirmation_password => "abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "abcd",
      :change_confirmation_password => "    ",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "abcd",
      :change_confirmation_password => "   ",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_not_match_confirmation],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "abc",
      :change_confirmation_password => "    ",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => nil
    },
    {
      :change_password => "abc",
      :change_confirmation_password => "   ",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "abc",
      :change_confirmation_password => "abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "",
      :change_confirmation_password => "",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "  ",
      :change_confirmation_password => "  ",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "a b",
      :change_confirmation_password => "a b",
      :change_password_error => TestChamber::UserUI.error_message[:error_password_too_short],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_too_short]
    },
    {
      :change_password => "abc abc",
      :change_confirmation_password => "abc abc",
    },
    {
      :change_password => " abcabc",
      :change_confirmation_password => " abcabc",
    },
    {
      :change_password => "abcabc ",
      :change_confirmation_password => "abcabc ",
    },
    {
      :change_password => "~!@^&*()_+{}|:<>?@*^$.&*$^&^!",
      :change_confirmation_password => "~!@^&*()_+{}|:<>?@*^$.&*$^&^!",
    },
    {
      :change_password => "m00ncak3",
      :change_confirmation_password => "m00ncak3",
    }
  ].each do |input|
    context "when inputting new password '#{input[:change_password]}' and confirmation password #{input[:change_confirmation_password]} its error should be #{input[:change_password_error]} and #{input[:change_confirmation_password_error]}" do
      let(:email){ "sgsTestRegister2#{Time.now.strftime('%Y%m%d%H%M%S%L')}@testt.com" }
      let(:email_address) { email }
      let(:password) { input[:change_password] }
      let(:confirm_password) { input[:change_confirmation_password] }

      xit "has error message" do
        user_ui.create!
        if user_ui.messages[:password_error]
          expect(user_ui.messages[:password_error]).to eql input[:change_password_error]
          expect(user_ui.messages[:confirm_password_error]).to eql input[:change_confirmation_password_error]
        else
          expect(user_ui.create_account_success).to eql email
        end
      end
    end
  end
end
