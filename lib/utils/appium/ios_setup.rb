module TestChamber::AppiumClient
  module IOS

    # Nothing to do for iOS locally, so this method is a no-op
    def configure_local
    end

    # These next two methods are needed for compatibility and will eventually
    # be implemented with the logic that does fuzzy matching for devices. See
    # spec/helpers/appthwack.rb for an example of what we'll do.
    def configure_saucelabs
    end

    def configure_appthwack
    end

    protected

    def searchable_file
      target_file = "#{app_name}.app/#{app_name}"

      if ['.zip'].include?(ext)
        unzip_file(app_path, target_file)
      elsif ['.app'].include?(ext)
        File.binread("#{app_path}/#{app_name}")
      else
        raise_configuration_error <<-DOC
          Invalid path: #{app_path}
          Make sure app_path in test_chamber/config/appium/appium.yml is a valid path.
        DOC
      end
    end
  end
end
