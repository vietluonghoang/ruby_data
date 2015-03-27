module TestChamber::AppiumClient
  module Android
    def configure_local
      check_environment_variables
      start_emulator
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
      target_file = 'classes.dex'

      if ['.apk'].include?(ext)
        unzip_file(app_path, target_file)
      else
        raise_configuration_error <<-DOC
          Invalid path: #{app_path}
          Make sure app_path in test_chamber/config/appium/appium.yml is a valid path.
        DOC
      end
    end

    private

    def check_environment_variables
      return if ENV['ANDROID_HOME'] && ENV['JAVA_HOME']
      return unless File.exists?(ENV['ANDROID_HOME'] + '/platform-tools/abd')
      return unless File.exists?(ENV['JAVA_HOME'] + '/bin/java')

      raise_configuration_error <<-DOC
        Make sure ANDROID_HOME and JAVA_HOME environment variables are set properly.
        Ensure $ANDROID_HOME/platform-tools/abd and $JAVA_HOME/bin/java exist.
        Run appium-doctor resolve any warnings and try again.
        https://github.com/Tapjoy/test_chamber/blob/develop/docs/appium.md#-running-locally
      DOC
    end

    def start_emulator
      running_emulator = `ps`.match(/tools\/emulator.*-avd \S+/i)
      avd = select_android_virtual_device

      return if running_emulator

      begin
        Util.exec_in_new_terminal("$ANDROID_HOME/tools/emulator -avd #{avd}")
      rescue UnsupportedSystemError
        raise_configuration_error <<-DOC
          Could not launch android device (emulator) in new terminal.
          Launch android device manually and run the specs again.
          https://github.com/Tapjoy/test_chamber/blob/develop/docs/appium.md#running-android-locally
        DOC
      end
    end

    def select_android_virtual_device
      avd = `$ANDROID_HOME/tools/android list avd`.match(/Name: (\S+)/)[1]

      return avd if avd

      raise_configuration_error <<-DOC
        Create and configure an Android Virtual Device (AVD) and try again.
        https://github.com/Tapjoy/test_chamber/blob/develop/docs/appium.md#running-android-locally
      DOC
    end
  end
end
