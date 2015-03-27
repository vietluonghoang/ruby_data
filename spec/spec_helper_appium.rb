# Appium specific test setup
# @todo: Create a capabilities builder and remove the logic from the spec helper
# to modularize and organize the code. This is a hot mess.

require 'helpers/appthwack'

# Backend specific configuration
if TestChamber::Config[:appium][:driver] == 'appthwack'
  appthwack = Appthwack::Client.new TestChamber::Config[:appthwack][:api_key]
  device = AppthwackDevice.new appthwack
  url = 'https://appthwack.com/wd/hub'
  appthwack_filename = device.os_name == 'ios' ? 'TJApp.zip' : 'TJApp.apk'
  addtl_caps = {
    :app            => appthwack.upload_file(
                        # TODO: Make the filename unique?
                        appthwack_filename,
                        File.new(TestChamber::Config[:appium][:app_path], 'r')
                       )["file_id"].to_s,
    :apiKey         => TestChamber::Config[:appthwack][:api_key],
    :automationName => TestChamber::Config[:appium][:backend],
    :project        => device.os_name == 'ios' ? "33593" : "26699",
    :deviceName     => device.name,
    :platformName   => device.os_name,
    :platformVersion => device.os_version
  }
elsif TestChamber::Config[:appium][:driver] == 'saucelabs'
  # @todo: remove SauceLabsClient and make a helper. Use SauceWhisk.
  saucelabs = TestChamber::SauceLabsClient.new
  url = 'http://ondemand.saucelabs.com:4444/wd/hub'
  filename = saucelabs.upload_app(TestChamber::Config[:appium][:app_path])

  addtl_caps = {
    :username         => TestChamber::Config[:saucelabs][:username],
    :'access-key'     => TestChamber::Config[:saucelabs][:access_key],
    :'appium-version' => "1.3.4",
    :app              => "sauce-storage:#{filename}",
  }
else
  url = TestChamber::Config[:appium][:cmd_exec] || 'http://localhost:4723/wd/hub'
  addtl_caps = {
    app: TestChamber::Config[:appium][:app_path],
  }
end

# capabilities for this appium session
desired_caps = {
  :deviceName       => TestChamber::Config[:appium][:device],
  :platformName     => TestChamber::Config[:appium][:os],
  :platformVersion  => TestChamber::Config[:appium][:version],
  :app              => TestChamber::Config[:appium][:app_path],
  :udid             => TestChamber::Config[:appium][:udid],
  # These TestChamber::Config don't really work. Might be an appium bug, might be the avd.
  # :avd              => TestChamber::Config[:appium][:avd],
  # :avdLaunchTimeout => TestChamber::Config[:appium][:avdLaunchTimeout]
}.merge!(addtl_caps)

# Meta config for appium
appium_lib_options = {
  server_url: url,
  # This is a server side wait, which we don't want. Capybara should handle it.
  wait: 0
}

# Full config hash
opts = {
  appium_lib: appium_lib_options,
  caps: desired_caps
}

driver_name = TestChamber::Config[:appium][:os].downcase.to_sym
Capybara.register_driver(driver_name) do |app|
  # appium_lib overrides method missing and raises an error if you haven't
  # started a session yet. By requiring it here, it means that a NoMethodError
  # that occurs before here will have the real traceback; otherwise it won't.
  #
  # https://github.com/appium/ruby_lib/issues/294
  require 'appium_capybara'
  Appium::Capybara::Driver.new app, opts
end
