module TestChamber::AppiumClient
  module Errors
    class AppiumConfigurationError < StandardError
    end

    def raise_configuration_error(text)
      error_msg = "Appium is not properly configured to run. #{text}"
      raise AppiumConfigurationError, error_msg
    end
  end
end
