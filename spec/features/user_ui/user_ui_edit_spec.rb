#
# UserUI edit spec is split across 2 files to be more optimally run by parallel_tests.
#

require 'spec_helper'

describe TestChamber::UserUI do
  include_context "User UI edit configuration"

  [
    {
      :change_password => "abcd",
      :change_confirmation_password => "dcba",
      :change_password_error => nil,
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_confirmation],
      :update_success_message => ""
    },
    {
      :change_password => "abc",
      :change_confirmation_password => "dcba",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "dcba",
      :change_confirmation_password => "abc",
      :change_password_error => nil,
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_confirmation],
      :update_success_message => ""
    },
    {
      :change_password => "",
      :change_confirmation_password => "dcba",
      :change_password_error => nil,
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_confirmation],
      :update_success_message => ""
    },
    {
      :change_password => "dcba",
      :change_confirmation_password => "",
      :change_password_error => nil,
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_confirmation],
      :update_success_message => ""
    },
    {
      :change_password => "",
      :change_confirmation_password => "abc",
      :change_password_error => nil,
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_confirmation],
      :update_success_message => ""
    },
    {
      :change_password => "abc",
      :change_confirmation_password => "",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "a bc de",
      :change_confirmation_password => "a d e  fg",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "a bc de",
      :change_confirmation_password => "abcde",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "a bc de",
      :change_confirmation_password => "abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "a bc de",
      :change_confirmation_password => "",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "abcde",
      :change_confirmation_password => "a bc de",
      :change_password_error => nil,
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_confirmation],
      :update_success_message => ""
    },
    {
      :change_password => "abc",
      :change_confirmation_password => "a bc de",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "",
      :change_confirmation_password => "a bc de",
      :change_password_error => nil,
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_confirmation],
      :update_success_message => ""
    },
    {
      :change_password => " abcd",
      :change_confirmation_password => "abcd",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "    ",
      :change_confirmation_password => "abcd",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "    ",
      :change_confirmation_password => "abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "   ",
      :change_confirmation_password => "abcd",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "   ",
      :change_confirmation_password => "abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "abcd",
      :change_confirmation_password => "    ",
      :change_password_error => nil,
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_confirmation],
      :update_success_message => ""
    },
    {
      :change_password => "abcd",
      :change_confirmation_password => "   ",
      :change_password_error => nil,
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_confirmation],
      :update_success_message => ""
    },
    {
      :change_password => " ",
      :change_confirmation_password => "    ",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "abc",
      :change_confirmation_password => "   ",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "abc",
      :change_confirmation_password => "abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "   ",
      :change_confirmation_password => "   ",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "    ",
      :change_confirmation_password => "    ",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "a b",
      :change_confirmation_password => "a b",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "abc abc",
      :change_confirmation_password => "abc abc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => " abcabc",
      :change_confirmation_password => " abcabc",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => nil,
      :update_success_message => ""
    },
    {
      :change_password => "abcabc ",
      :change_confirmation_password => "abcabc ",
      :change_password_error => TestChamber::UserUI.error_message[:error_password],
      :change_confirmation_password_error => TestChamber::UserUI.error_message[:error_password_confirmation],
      :update_success_message => ""
    },
    {
      :change_password => "",
      :change_confirmation_password => "",
      :change_password_error => nil,
      :change_confirmation_password_error => nil,
      :update_success_message => TestChamber::UserUI.error_message[:update_success_message]
    }
  ].each do |input|
    context "when inputing new password '#{input[:change_password]}' and confirmation pass '#{input[:change_confirmation_password]}' its error should be '#{input[:change_password_error]}' and '#{input[:change_confirmation_password_error]}'" do
      let(:password) { input[:change_password] }
      let(:confirm_password) { input[:change_confirmation_password] }

      it "has error_message" do
        user_ui.update!
        expect(user_ui.messages[:password_error]).to eql input[:change_password_error]
        expect(user_ui.messages[:confirm_password_error]).to eql input[:change_confirmation_password_error]
        expect(user_ui.messages[:flash_message]).to include input[:update_success_message]
      end
    end
  end
end
