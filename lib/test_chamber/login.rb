module TestChamber
  # Convenience methods for dealing with env vars for login
  module Login
    # dashboard username from .env
    def username
      raise "TEST_USERNAME env var should be set to dashboard user" unless ENV['TEST_USERNAME']
      ENV['TEST_USERNAME']
    end

    # dashboard password from .env
    def password
      raise "TEST_PASSWORD env var should be set to dashboard user's password" unless ENV['TEST_PASSWORD']
      ENV['TEST_PASSWORD']
    end

    # convenience method to globally cache login cookies across capybara sessions, since it starts
    # a new session per spec
    def save_auth_cookies!
      page.driver.browser.manage.add_cookie(name: 'dashboard_asset_version', value: TestChamber.dashboard_asset_string) if TestChamber.dashboard_asset_string
      TestChamber.user_cookies = page.driver.browser.manage.all_cookies
    end
  end
end
