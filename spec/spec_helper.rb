require 'rubygems'
require 'spork'

# This spec helper is organized so that as much non-application code is loaded
# upfront as possible.  In addition, the initial user and partner for the session
# (including the browser) get defined upfront.  This allows spork to fork the
# process and run specs each time its requested.
#
# Ultimately there are probably some ways to clean this up through something
# like Rails-style reloading.  However, that requires changes to the TestChamber
# library code that will require additional effort.

# Load all non-application code / configurations upfront
Spork.prefork do
  require 'selenium/webdriver'
# Allow a custom Firefox binary
Selenium::WebDriver::Firefox::Binary.path = ENV['FIREFOX_PATH'] if ENV['FIREFOX_PATH']

# Check for incompatible firefoxen.
begin
  version = `#{Selenium::WebDriver::Firefox::Binary.path} -v`.split(" ").last.to_i
  raise "Unsupported Firefox version. Please downgrade to Firefox 35 from http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/35.0.1/" if version >= 36
rescue Errno::ENOENT
  raise "Could not find Firefox binary. Ensure you have Firefox installed or on your path: http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/35.0.1/"
end

# The context for the user session that gets initialized when specs are started.They'll then be used in forks
# These configurations will get populated later on in the spec helper and used
# either within forks of the process (if used within spork) or in-process.
USER_SESSION = {:cookies => nil, :created_partners => []}

# Load test dependencies
$LOAD_PATH.unshift(File.expand_path('..', __FILE__))
require 'active_record'
require 'yaml'
require 'capybara/rspec'
require 'rspec/expectations'
require 'logger'
require 'erb'
require 'pry'

# Load TestChamber::Config initializer first for settings validation
$: << File.absolute_path('.')
require File.join('config', 'initializers', 'configliere')
# Load all initializers
Dir['./config/initializers/**/*.rb'].sort.each { |f| require f }

# Ensure tmp directories exist
%w{logs screenshot}.each do |dir|
  begin
    Dir.mkdir(dir) unless File.exists?(dir)
  rescue Errno::EEXIST
    # With parallel rspec there can be a race to create the dir.
    # We just care that it exists, so nothing to see here; move along.
  end
end

# Configure capybara
Capybara.configure do |config|
  # When running in parallel, TJS gets slow. Use this timeout to compensate.
  config.default_wait_time = TestChamber::Config[:capybara_wait_time]

  #config.match = :prefer_exact
  config.run_server = false
  config.ignore_hidden_elements = false
end

# Load the selenium driver and make the default. This is required before loading
# Test Chamber in order to allow the master process in spork to load and own the
# browser process. We don't load appium here because we need to run test setup
# like partner/user creation before every test, even appium tests.
require 'spec_helper_selenium'
Capybara.javascript_driver = :selenium
Capybara.default_driver = :selenium


# Define decryption config
SYMMETRIC_CRYPTO_SECRET = '63fVhp;QqC8N;cV2A0R.q(@6Vd;6K.\\_'

# Runs a given block within a child process and returns the result of
# the block
def do_in_child
  read, write = IO.pipe
  pid = fork do
    read.close
    result = yield
    Marshal.dump(result, write)
    exit!(0)
  end

  write.close
  result = read.read
  Process.wait(pid)
  raise "Child fork failed" if result.empty?
  Marshal.load(result)
end

# Gets the default partner for the user identified by the given email
def get_default_partner(user_email)
  u = TestChamber::Models::User.where(:email => user_email).first
  raise "Could not find a user on the system that matched the email '#{user_email}'." unless u
  u.partners.first.id
end

# Loads and configures TestChamber
def load_test_chamber
  # load shared examples
  Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

  #load the app
  require 'test_chamber'

  # Target server
  TestChamber.target_url = TestChamber::Config[:target_url]

  TestChamber.dashboard_asset_string = TestChamber::Config[:dashboard_asset_version]

  # Enable logging
  TestChamber.logger = Logger.new('logs/dev.log') if ENV['ENABLE_LOCAL_LOGGING'] == 'true'

  #initializing default values

  TestChamber.default_wait_for_timeout = TestChamber::Config[:default_wait_timeout]
  TestChamber.default_wait_for_interval = TestChamber::Config[:default_wait_interval]

  TestChamber.created_partners ||= Set.new
  TestChamber.current_device = TestChamber::Device.android_10_point_1

  TestChamber.user_cookies = USER_SESSION[:cookies]
  if TestChamber::Config[:test_username]
    TestChamber.default_partner_id = get_default_partner(TestChamber::Config[:test_username])
  end

  # Check Appium dependencies
  TestChamber::AppiumClient.setup
end

# Finds and configures the user used for authenticating requests with the
# dashboard and other APIs
def find_or_create_test_user
  unless TestChamber::Config[:tc_no_login]
    unless TestChamber::Config[:test_username]
      email = "#{SecureRandom.uuid}@tapjoy.com"
      password = SecureRandom.uuid

      TestChamber::UserAPI.new(
        is_super_user: true,
        email_address: email,
        password: password,
        confirm_password: password,
        company_name: 'TestChamber Inc.',
        time_zone: 'Eastern Time (US & Canada)',
        country: 'United States',
        language: 'en',
        is_advertiser: true,
        is_publisher: true,
        agree_terms_of_service: true
      ).create!

      puts "Created user #{email} with password #{password}"
      u = TestChamber::Models::User.where(:email => email).first
      raise "Unable to find user we just created with email #{email}" unless u

      # give new user all the roles
      test_user = TestChamber::Models::User.where(:email => 'test@tapjoy.com').first
      u.user_roles = test_user.user_roles
      u.save!

      # TODO save these somewhere better
      Settings(test_username: email)
      TestChamber::Config(test_password: password)
      ENV['TEST_USERNAME'] = email
      ENV['TEST_PASSWORD'] = password
    end
  end
end

# Logs the currently configured test user into the dashboard
def login_test_user
  unless TestChamber::Config[:tc_no_login]
    dash = TestChamber::Dashboard.new
    dash.login
  end
end

def create_test_partner
  TestChamber.default_partner_id = get_default_partner(TestChamber::Config[:test_username])
  TestChamber.created_partners << TestChamber.default_partner_id

  p = TestChamber::Partner.new(id: TestChamber.default_partner_id)
  p.configure_partner
  p.approve_partner
  p
end

# Initializes the user session within the browser.  Since this will be shared
# context from spec to spec, it'll be run in a separate fork in order to not
# affect the main process.  In particular, this allows code to be changed
# when running specs in spork.  If TestChamber were loaded in the main process,
# it would be more difficult to reload code on each spec run.
def initialize_session
  Capybara.current_session.driver.browser

  # Set the test user if it isn't already defined
  context = do_in_child do
    load_test_chamber
    find_or_create_test_user
    login_test_user
    create_test_partner

    {
      'username' => TestChamber::Config[:test_username],
      'password' => TestChamber::Config[:test_password],
      'partners' => TestChamber.created_partners,
      'cookies' => TestChamber.user_cookies
    }
  end
  TestChamber::Config(test_username: context['username'])
  TestChamber::Config(test_password: context['password'])
  # Updating environment variables as all uses of ENV have not been replaced
  # with use of the TestChamber::Config object.
  ENV['TEST_USERNAME'] = TestChamber::Config[:test_username]
  ENV['TEST_PASSWORD'] = TestChamber::Config[:test_password]
  USER_SESSION[:cookies] = context['cookies']
  USER_SESSION[:created_partners] = context['partners']

  # Now that all the setup is done, load appium if needed
  if TestChamber::Config['tc_driver'] == 'appium'
    # Appium Capybara overrides some Capybara methods, specifically the :id selector.
    # To limit the scope of this, we only include appium capybara when appium tests
    # are run. The worst that will happen if you have a mixed appium/selenium context
    # is that `find(:id, 'selector') will NoMethodError. You can still access the exact
    # same functionality via `find(:css, '#selector').
    require 'spec_helper_appium'
  end
end

# Cleans up any data left behind by TestChamber, such as partners.
def teardown_test_chamber
  if TestChamber::Config[:tc_partner_delete]
    TestChamber::Models::Partner.destroy_all(id: Array(TestChamber.created_partners))
  end
end

# Helper that sets the current driver based on metadata.
def set_driver(test)
  if test.metadata[:appium] && (TC::Config['tc_driver'] == 'appium' ||
                                RSpec.configuration.filter.rules[:appium])
    Capybara.current_driver = TC::Config[:appium][:os].downcase.to_sym
  else
    Capybara.current_driver = :selenium
  end
  Capybara.default_driver = Capybara.current_driver
end

### Configure Spork

# Ensure we teardown TestChamber.  Unfortunately there are no hooks in
# Spork for the shutdown process and signal traps / at_exit hooks aren't
# possible since Spork's handlers will always run first and call exit!(0)
Spork::Server.class_eval do
  alias_method :original_abort, :abort
  def abort
    # Since this is executing within a signal handler, we need to teardown
    # TestChamber within a thread.  Certain things (like requiring files)
    # can't run within the context of a signal handler
    runner = Thread.new do
      load_test_chamber
      TestChamber.created_partners += USER_SESSION[:created_partners]
      teardown_test_chamber
    end
    runner.join

    # Delegate back to the original implementation
    original_abort
  end
end

# Each time spork runs, be to sure to load test chamber
Spork.each_run { load_test_chamber }

### Configure RSpec

# Use the add_context method in specs to track useful debugging information.
# It can be called multiple times and everything passed to it will be printed out with any failure message
# if the specs fail.
module ContextHelper
  def add_context(c)
    @context ||= []
    @context << c
  end

  def context
    @context || []
  end
end

RSpec.configure do |c|
  # CI Reporter doesn't play nice with .rspec files or command line options, so
  # we're including it here, AFTER everything else, so it can't blow them away.
  if ENV['CI_REPORTS']
    require 'ci/reporter/rake/rspec_loader'
    c.formatter = CI::Reporter::RSpec3::Formatter
  end
  c.alias_it_should_behave_like_to :it_validates, "validates:"
  c.filter_run_excluding :pending => true
  include ContextHelper

  # Only run appium tests for an appium driver.
  if TestChamber::Config['tc_driver'] == 'appium' || c.filter.rules[:unit]
    c.filter_run_including :appium
  else
    c.filter_run_excluding :appium
  end

  c.before :context do |test|
    set_driver(test.class)
    # Think of this next bit like 'do something before each context'. It ensures
    # that we set the driver for each arbitrarily nested context, as well as each
    # context alongside the current context, by prepending a before :context hook
    # to each context. It also *resets* the driver by appending an after :context
    # hook which accesses the parent context and sets the driver from that context.
    #
    # When no nested contexts, Rspec just gives you the context you're in, which
    # means, at worst, we set Capybara.current_driver twice for a context.
    #
    # See spec/internal/unit/driver_context_spec.rb for more information.
    #
    # TODO: This is really helpful and unsupported by any gem I could find. This
    # should be extracted into a `before :each_context` hook and turned into an
    # RSpec Pull Request/Plugin. It's super neat that you can do this. I looked
    # at writing this as an RSpec Hook but that was like starting into a black hole.
    test.class.children.each do |context|
      context.prepend_before :context do |nested_context|
        set_driver(nested_context.class)
        nested_context.class.append_after :context do
          set_driver(nested_context.class.parent_groups.first)
        end
      end
    end
  end

  c.around :example do |test|
    # Sometimes selenium has trouble talking to firefox. This will result
    # in a Net::ReadTimeout error. In this case, we just want to try again.
    # If it fails twice consecutively, we should raise because something is wrong.
    2.times do |i|
      test.run
      break unless test.example.exception.class == Net::ReadTimeout
      # Don't clear the exception the second time through
      if i < 1
        puts "NetRead::Timeout, retrying test."
        test.example.instance_variable_set('@exception', nil)
        Capybara.current_session.driver.quit
      end
    end
  end

  c.before :example do |test|
    set_driver(test)
    TestChamber.current_device = TestChamber::Device.android_10_point_1
  end

  c.after :example do |test|
    begin
      if test.exception != nil
        # if there's an error taking screenshots, it blows away the traceback.
        # This will not silently pass but also won't destroy our traceback.
        begin
          long_name = "#{test.full_description}".gsub(/[: \$\'\"\n\`\>\<\/]/, '_')
          screenshot = "screenshot/#{long_name}.png"
          Capybara.page.driver.save_screenshot screenshot
          puts "Since your spec failed we put a screenshot in '#{screenshot}'"
        rescue Errno::ECONNREFUSED => e
          puts "Error while taking screenshot: #{e.message}"
          # swallow the exception and let things roll along.
        end
      end

      ctxt = if test.context && test.context.any?
               test.context
             else
               test.example_group_instance.context
             end

      if test.exception && ctxt.any?
        test.exception.message << "\n\nAdditional test context:\n#{ctxt}"
      end
    end

    if [:ios, :android].include? Capybara.current_driver
      Capybara.current_session.driver.quit
    end
  end

  # Ensure TestChamber data gets cleaned up
  c.after :suite do
    # Only add the default partner when spork isn't being used since spork will
    # handler cleanup of the partner when its process ends
    TestChamber.created_partners += USER_SESSION[:created_partners] unless Spork.using_spork?
    teardown_test_chamber
  end
end

# Create the user session context
initialize_session unless TestChamber::Config[:tc_no_browser]

# Only load TestChamber if we're not using Spork since TestChamber will get
# loaded in each fork of Spork
load_test_chamber unless Spork.using_spork?

end
