module TestChamber
  # Wrapper class for common dasboard tasks
  class Dashboard
    include Capybara::DSL
    include TestChamber::Login

    def refresh_browser_cookies
      # selenium has to be on a page in the domain in order to set cookies
      visit "#{TestChamber.target_url}/dashboard/tools"
      page.driver.browser.manage.delete_all_cookies
      TestChamber.user_cookies.each do |cookie|
        # Some cookies set have a leading dot before the hostname. Selenium will
        # only set cookies for the domain you are on and the leading dot breaks
        # this. Spirra cookies use a leading dot, so for now, let's just strip the
        # dot.
        cookie[:domain].gsub! /^\./, ''
        # 'Monkey' the spirra cookie so that it's domain points to the TIAB, else
        # spec's will be logged out.
        # TODO Update this when 5rocks login works
        if cookie[:name] == '_spirra'
          cookie[:domain] = URI.parse(TestChamber.target_url).host
        end
        next if cookie[:domain].start_with? '5rocks'
        page.driver.browser.manage.add_cookie(cookie)
      end
    end

    def ui_login
      visit "#{TestChamber.target_url}/login"
      # This is because of a bug in dashboard where we are still being prompted to use the new layout
      page.driver.browser.manage.add_cookie({:name=>"navigation_layout",
                                             :value=>"v2",
                                             :path=>"/",
                                             :domain=> URI.parse(TestChamber.target_url).hostname,
                                             :expires=> 6.months.from_now,
                                             :secure=>false})

      if page.find('#user_session_username')
        fill_in 'user_session_username', :with => username
        fill_in 'user_session_password', :with => password
        click_button 'user_session_submit'
        # Need to explicitly approve a device because of the 5rocks redirect.
        visit "#{TestChamber.target_url}/approve_device"
        save_auth_cookies!
      end
    end

    # Log in and cache the login cookies so we only have to log in once per test session
    def login
      if TestChamber.user_cookies
        refresh_browser_cookies
      else
        ui_login
      end
    end

    # Log out and clear the cached cookies
    def logout
      visit "#{TestChamber.target_url}/logout"
      TestChamber.user_cookies = nil
    end

    # For users that aren't on the v2 style, switch to that
    def use_new_look
      visit "#{TestChamber.target_url}/apps"
      look_switcher = page.first("#switch_look", visible: true)
      # some users are already on the new look by default so just roll with it.
      look_switcher.click if look_switcher
    end

    def get_reward_key(params)
      visit "#{TestChamber.target_url}/dashboard/tools/device_info?#{params.to_query}"
      click_info = page.find("tr[id='click_#{params[:udid]}#{params[:offer_id]}']").text
      click_info[/Reward ID: (\w|-)+/].split(" ").last
    end
  end
end
