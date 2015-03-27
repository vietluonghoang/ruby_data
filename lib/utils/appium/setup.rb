module TestChamber::AppiumClient

  def self.setup
    self.extend TestChamber::AppiumClient::Errors

    tc_driver = TestChamber::Config[:tc_driver]

    return unless tc_driver == 'appium'
    os = TestChamber::Config[:appium][:os].to_sym
    ext = TestChamber::Config[:appium][:app_path].match(/\.\w+$/)[0]
    emulator = TestChamber::Config[:appium][:device]

    driver = TestChamber::Config[:appium][:driver]
    appium_drivers = {
      'local'     => Local,
      'saucelabs' => SauceLabs,
      'appthwack' => AppThwack
    }
    return unless os_matches_extension?(os, ext)

    add_device_module(appium_drivers[driver].new, os).configure
  end

  def self.add_device_module(driver, os)
    device_module = {
      android: TestChamber::AppiumClient::Android,
      ios:     TestChamber::AppiumClient::IOS
    }
    driver.extend device_module[os]
    driver.extend TestChamber::AppiumClient::Errors
  end

  def self.os_matches_extension?(os, ext)
    # Extensions are also hardcoded in ios_setup.rb and android_setup.rb
    # Any change here will also require a change in the searchable_file method.
    valid_extensions = {
      android: ['.apk'],
      ios: ['.app', '.zip']
    }

    valid_extensions[os].include?(ext) ||
    raise_configuration_error(<<-DOC
      test_chamber/config/appium/appium.yml is not properly configured.
      Selected OS does not match app_path filetype.
      OS: #{os}
      Ext: #{ext}
      Valid Extensions: #{valid_extensions}
    DOC
    )
  end
end
