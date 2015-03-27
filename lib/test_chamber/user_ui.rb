module TestChamber
  class UserUI < User

    @@error_message = {
      :error_should_look_like_email_address => "Email should look like an email address.",
      :error_email_has_been_taken => "Email has already been taken",
      :error_field_is_required => "This field is required",
      :error_unable_to_update => "Unable to update.",
      :update_success_message => "account updated",
      :create_user_success_message => "account updated.",
      :error_password => "Password must be at least 4 characters and contain no spaces and match confirmation",
      :error_password_confirmation => "Password Confirmation must match password",
      :error_email_has_special_character => "Email should look like an email address.,Username should use only letters, numbers, spaces, and .-_@ please.",
      :error_password_too_short => "is too short (minimum is 4 characters)",
      :error_password_not_match_confirmation => "doesn't match confirmation",
      :error_email_too_short => "is too short (minimum is 6 characters)",
      :error_should_look_like_an_email_address => "should look like an email address.",
      :error_email_has_already_been_taken => "has already been taken",
      :create_user_success_message_register => "account created",
      :error_cant_blank => "can't be blank",
      :tos_is_not_checked => "Not Checked",
    }

    def self.error_message
      @@error_message
    end

    def initialize(options={})
      super(options)
    end

    def create_super_user!
      reset_messages

      visit("#{TestChamber.target_url}/logout")
      visit("#{TestChamber.target_url}/register")

      fill_in('user[email]', :with => @email_address) if @email_address
      fill_in('partner_name', :with => @company_name) if @company_name
      fill_in('user[password]', :with => @password) if @password
      fill_in('user[password_confirmation]', :with => @confirm_password) if @confirm_password
      select(@time_zone, :from => "user[time_zone]") if @time_zone
      select(@country, :from => "user[country]")
      select(@language, :from => "user[preferred_language]")

      find('#user_account_type_advertiser').set(@is_advertiser)
      find('#user_account_type_publisher').set(@is_publisher)
      find('#user_terms_of_service').set(@agree_terms_of_service)

      click_button('Create Account')

      if page.has_css?('.formError')
        page.all("#new_user").each do |tr|
          if tr.find('tr:nth-child(1)').first('.formError')
            @messages[:email_error] = tr.find("tr:nth-child(1) div.formError").text.to_s
          end
          if tr.find('tr:nth-child(2)').first('.formError')
            @messages[:partner_name_error] = tr.find('tr:nth-child(2) div.formError').text.to_s
          end
          if tr.find('tr:nth-child(3)').first('.formError')
            @messages[:password_error] = tr.find('tr:nth-child(3) div.formError').text.to_s
          end
          if tr.find('tr:nth-child(4)').first('.formError')
            @messages[:confirm_password_error] = tr.find('tr:nth-child(4) div.formError').text.to_s
          end
          if tr.find('tr:nth-child(5)').first('.formError')
            @messages[:time_zone_error] = tr.find('tr:nth-child(5) div.formError').text.to_s
          end
        end
      else

        # @messages[:is_accept_tos_checked] set to 'Not Checked' marked as TOS unchecked
        # there is no error message displayed while unchecking TOS

        if page.first('.field_with_errors')
          @messages[:is_accept_tos_checked] = "Not Checked"
        end

        # There is no succeeded message when registering successfully new account. Thus, we'll check if the registered email
        # appears at the top-right corner of the page, then the registration succeeded.

        if page.first("div#top_nav li", :text => "#{@email_address}")
          @create_account_success = page.find("div#top_nav li:first-child", :text => "#{@email_address}").text
        end
      end
    end

    def create_normal_user!
      reset_messages

      visit("#{TestChamber.target_url}/dashboard/v2/account?")

      # This code snippet catches the case that the user logs out unexpectedly. This case happens when user cookies has
      # been changed after running some "edit" cases.
        if page.first("#login_mobile")
          TestChamber.user_cookies = nil
          dash = TestChamber::Dashboard.new
          dash.login
        end

      Util.wait_for do
        visit("#{TestChamber.target_url}/dashboard/v2/account?")
        page.has_css?('.standard-table > tbody:nth-child(2) > tr:nth-child(1)')
      end

      page.find("form.new-user-form").fill_in("email", :with => @email_address) if @email_address

      select_item(@time_zone, :from => "form.new-user-form label[for='time_zone']+div a.chosen-single")
      select_item(@country, :from => "form.new-user-form label[for='country']+div a.chosen-single")

      page.find("form.new-user-form").click_button('Save')

      if page.has_css?("#alerts ul li")
        msg = page.find("#alerts ul li").text
        if msg != "" && !msg.include?("account created")
          @messages[:email_error] = msg
        else
          @messages[:flash_message] = msg
        end
      end

      if page.first("form.new-user-form label[for='email']+div.field.invalid")
        @messages[:email_error] = page.find("form.new-user-form label[for='email']+div.field.invalid aside.error-message")
                                      .text
      end

      if page.first("form.new-user-form label[for='time_zone']+div.field.invalid")
        @messages[:time_zone_error] = page.find("form.new-user-form label[for='time_zone']+div.field.invalid aside.error-message")
                                          .text
      end
      if page.first("form.new-user-form label[for='country']+div.field.invalid")
        @messages[:country_error] = page.find("form.new-user-form label[for='country']+div.field.invalid aside.error-message")
                                        .text
      end
    end

    def update!
      reset_messages

      # When updating the user details at the second time, webdriver gets stuck and does not open the page.
      # Thus, we duplicate the "visit" command to bypass this issue.

      visit("#{TestChamber.target_url}/dashboard/v2/account?")
      Util.wait_for do
        visit("#{TestChamber.target_url}/dashboard/v2/account?")
        page.has_css?('.standard-table > tbody:nth-child(2) > tr:nth-child(1)')
      end

      update_user_form = page.find('form.standard-form')
      update_user_form.fill_in('email', :with => @email_address) if @email_address
      update_user_form.fill_in('password', :with => @password) if @password
      update_user_form.fill_in('password_confirmation', :with => @confirm_password) if @confirm_password
      select_item(@country, :from => "form.standard-form label[for='country']+div a.chosen-single")
      select_item(@time_zone, :from => "form.standard-form label[for='time_zone']+div a.chosen-single")
      select_item(@language, :from => "form.standard-form label[for='preferred_language']+div a.chosen-single")

      if @receive_campaign_emails
        page.find("div.field.radio label:nth-child(1) span:nth-child(2)").click
      else
        page.find("div.field.radio label:nth-child(2) span:nth-child(2)").click
      end

      update_user_form.click_button('Save')

      if page.has_css?("#alerts ul li")
        msg = page.find("#alerts ul li").text
        if msg != "" && !msg.include?("account updated")
          @messages[:email_error] = msg
        else
          @messages[:flash_message] = msg
        end
      end

      # We add more condition for this case since the flash error message and validation message for the invalid email
      # display at the same time.
      if page.first("div#user-management-form label[for='email']+div.field.invalid") && @messages[:email_error] == ""
        @messages[:email_error] = page.find("div#user-management-form label[for='email']+div.field.invalid aside.error-message")
                                      .text
      end

      if page.first("div#user-management-form label[for='password']+div.field.invalid")
        @messages[:password_error] = page.find("div#user-management-form label[for='password']+div.field.invalid aside.error-message")
                                         .text
      end
      if page.first("div#user-management-form label[for='password_confirmation']+div.field.invalid")
        @messages[:confirm_password_error] = page.find("div#user-management-form label[for='password_confirmation']+div.field.invalid aside.error-message")
                                                 .text
      end
    end

    def reset_messages
      @messages = {
        :is_accept_tos_checked => true,
        :flash_message => "",
        :email_error => ""
      }
    end
  end
end
