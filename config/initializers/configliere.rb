require 'configliere'
require 'zip'

module TestChamber

  # TestChamber::Config class should be used to avoid collision with TestChamber::Config
  Config = Settings

  def self.Config(*args, &block)
    Settings(*args, &block)
  end

  # Instantiate TestChamber::Config here using the TestChamber::Config object -
  # https://github.com/infochimps-labs/configliere

  TestChamber::Config.use :config_block

  # List of appium params to override from env variables
  APPIUM_PARAMS = [
    'APPIUM_DRIVER',
    'APPIUM_OS',
    'APPIUM_VERSION',
    'APPIUM_DEVICE',
    'APPIUM_APP_PATH',
    'APPIUM_BACKEND'
  ]

  # Load offer parameters
  Dir['./config/offer_params/*.yml'].each do |file|
    TestChamber::Config.read(file)
  end

  # Load test chamber TestChamber::Config from the environment, the description will be
  # displayed in related exceptions raised from required TestChamber::Config.
  TestChamber::Config.define('target_url', env_var: 'TARGET_URL', required: true,
                  description: 'Should point to the system under test.')
  TestChamber::Config.define('tc_driver', env_var: 'TC_DRIVER',
                  description: 'The driver to run tests with, either selinium '\
                                'or appium', default: 'selenium')
  TestChamber::Config.define('capybara_wait_time', env_var: 'CAPYBARA_WAIT_TIME',
                  description: 'Default wait time for Capybara', default: 20)
  TestChamber::Config.define('dashboard_asset_version', env_var: 'DASHBOARD_ASSET_VERSION')
  TestChamber::Config.define('default_wait_timeout', env_var: 'DEFAULT_WAIT_TIMEOUT',
                  description: 'The default wait value for wait_for blocks',
                  default: 30)
  TestChamber::Config.define('default_wait_interval', env_var: 'DEFAULT_WAIT_INTERVAL',
                  description: 'The default interval to use in wait_for blocks',
                  default: 2)
  TestChamber::Config.define('tc_no_login', env_var: 'TC_NO_LOGIN',
                  description: 'Set to true to disable auto-login to the TIAB',
                  default: false)
  TestChamber::Config.define('test_username', env_var: 'TEST_USERNAME',
                  description: 'Username for test login')
  TestChamber::Config.define('test_password', env_var: 'TEST_PASSWORD',
                  description: 'Password for test login')
  TestChamber::Config.define('tc_partner_delete', env_var: 'TC_PARTNER_DELETE',
                             description: 'Delete partners after each test run. This is used to keep generated partners from clogging up the jobs on tiab after many test runs. It is not normally necessary to set this in development.',
                             default: false)
  TestChamber::Config.define('tc_no_browser', env_var: 'TC_NO_BROWSER', default: false)

  # Define and Load appium configuration
  appium_required = TestChamber::Config[:tc_driver] == 'appium'
  APPIUM_PARAMS.each do |var|
    TestChamber::Config.define("appium.#{var.sub('APPIUM_', '').downcase}",
                    required: appium_required)
  end

  if appium_required
    raise "Please create an Appium config at config/appium/appium.yml" unless File.file?('./config/appium/appium.yml')
  end


  Dir['./config/appium/*.yml'].each do |file|
    TestChamber::Config.read(file) unless file.slice 'sample_'
  end

  # Block called when TestChamber::Config.resolved! is called at the end of the config.
  # resolve chain
  TestChamber::Config.finally do |c|
    # Active record initializer requires TARGET_URL

    unless c[:target_url] =~ URI::regexp
      puts 'TARGET_URL env var should point to the system under test. Example:'\
          ' http://my-tapinabox.tapjoy.net'
      raise "Invalid TARGET_URL environment variable: #{c[:target_url]}"
    end
    c[:target_url] = c[:target_url].gsub(/\/$/,'').downcase
    ENV['TARGET_URL'] = c[:target_url]

    if c[:test_username]
      puts "\n***WARNING***"
      puts "Using configured username '#{c[:test_username]}' to log in. Note that"\
       'this is not how tests should be run. You should unset this and allow '\
       'TestChamber to create a new user for test runs.'
      unless c[:test_password]
        raise 'You also need to set the TEST_PASSWORD environment variable'
      end
    end

    # Override appium config from env variables, so we can use env variables in
    # jenkins to control things like OS and version.
    APPIUM_PARAMS.each do |var|
      # Strip the 'APPIUM_' from the env var to match the yml filenames
      c["appium.#{var.sub('APPIUM_', '').downcase}".to_sym] = ENV[var] if ENV[var]
    end
  end
  TestChamber::Config.resolve!

end
