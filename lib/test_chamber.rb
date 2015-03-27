require 'riak'
require 'monetary_value'
require 'monetary_value/support/active_record'
require 'rest_client'
require 'pry'
require 'json'
require 'streamio-ffmpeg'

module TestChamber
  TEST_CHAMBER_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  class << self
    attr_accessor :target_url
    attr_accessor :current_device
    attr_accessor :default_partner_id
    attr_accessor :default_wait_for_timeout
    attr_accessor :default_wait_for_interval
    attr_accessor :user_cookies
    attr_accessor :dashboard_asset_string
    attr_accessor :logger

    # The statz jobs on the test system operate on all Offers created by Partners
    # which were added since the system started. If we continue to run lots of tests
    # the number of Partners created goes way up and the jobs take too long to complete.
    # So each test run should track which Partners it created and clean
    # them up at the end of each test run.
    # If it turns out that this destroys some diagnostic information we'll need to
    # record that some other way.  We do not have to destroy the offers associated
    # with those partners so we can still use those for debugging if necessary although
    # since their partners are gone they are likely non-functional after the tests.
    attr_accessor :created_partners

    def fake_has_offers_url
      "#{TestChamber.target_url}:4568"
    end

    # Global connection to riak shared by all objects
    def riak
      @riak ||= Riak::Client.new(host: TestChamber.target_url.split('/').last, pb_port: 8087, protocol: 'pbc')
    end

    def object_cache
      @object_cache ||= Hash.new
    end
  end
end

def require_dir(dir)
  Dir[File.dirname(__FILE__) + "/../lib/#{dir}/*.rb"].each do |file|
    require "#{dir}/#{File.basename(file, File.extname(file))}"
  end
end

require 'active_support/core_ext/string'
require 'active_support/inflector/inflections'
require 'active_support/inflector/methods'
require 'active_model'

require 'faraday'
require 'faraday_middleware'
require 'faraday-cookie_jar'
require 'http/cookie_jar'
require 'utils/faraday/middleware'

require 'utils/object_encryptor'
require 'utils/confirmation_dialog'
require 'utils/uuid'
require 'utils/random'
require 'utils/http_waiter'
require 'utils/select_from_chosen'
require 'utils/dashboard_utility'
require 'utils/dropzone'
require 'utils/action_decorator'
require 'utils/appium/setup'
require 'utils/appium/local_setup'
require 'utils/appium/saucelabs_setup'
require 'utils/appium/appthwack_setup'
require 'utils/appium/ios_setup'
require 'utils/appium/android_setup'
require 'utils/appium/errors'

require 'test_chamber/rest'
require 'test_chamber/login'
require 'test_chamber/unique_name'

require 'utils/connect_request_data'
require 'test_chamber/statz'
require 'test_chamber/dashboard'
require 'test_chamber/object_cache'

require 'test_chamber/util'
require 'test_chamber/creator'
require 'test_chamber/api_behavior'
require 'test_chamber/ui_behavior'

# load offer related classes and modules.
# These have to go first because others depend on them
require 'test_chamber/offer/offer_params'
require 'test_chamber/offer/api_behavior'
require 'test_chamber/offer/store_id_enabler'
require 'test_chamber/properties'
require 'test_chamber/offer'

# have to require this first as some other creators use it
require 'test_chamber/offer/creator/engagement_api'
require 'test_chamber/offer/properties'
require_dir 'test_chamber/offer/properties'
require_dir 'test_chamber/offer/creator'
require_dir 'test_chamber/offer/editor'
require_dir 'test_chamber/offer'
require 'test_chamber/app/creator/app_ui_base'
require_dir 'test_chamber/app/creator'
require 'test_chamber/app'
require 'test_chamber/app/properties'
require_dir 'test_chamber/app'

require 'test_chamber/offerwall/mobile_methods'
require_dir 'test_chamber/app/properties'
require_dir 'test_chamber/offerwall'

require_dir 'test_chamber/offer/convertor'
require_dir 'test_chamber/offer/convertor/action'

# require this first since ios and android include it.
require 'test_chamber/offer/convertor/install/web'
require_dir 'test_chamber/offer/convertor/install'
require_dir 'test_chamber/offer/convertor/video'
require_dir 'test_chamber/offer/convertor/v2i'
require_dir 'test_chamber/offer/convertor/compound'
require_dir 'test_chamber/offer/convertor/compound/video'
require_dir 'test_chamber/offer/convertor/compound/end_card'

require 'test_chamber/app'
require 'test_chamber/partner'
require 'test_chamber/reseller'
require 'test_chamber/currency'
require 'test_chamber/offerwall'
require 'test_chamber/web_request'
require 'test_chamber/optsoa'
require 'test_chamber/saucelabs'
require 'test_chamber/device'

require 'test_chamber/offer'
require 'test_chamber/user'
require 'test_chamber/user_api'
require 'test_chamber/user_ui'

require 'test_chamber/eventservice/earning_configuration'
require 'test_chamber/eventservice/placement'
require 'test_chamber/eventservice/placement_offer'

require 'test_chamber/placement_service/placement'
require 'test_chamber/placement_service/action'

require 'test_chamber/publisher_user'

require 'test_chamber/util'

require 'models/uuid_primary_key'

require 'test_chamber/activity_log.rb'


#Load Tjs models
Dir[File.dirname(__FILE__) + '/../lib/models/*.rb'].each do |file|
  require "models/#{File.basename(file, File.extname(file))}"
end

#Always load the db connection model first
require "#{File.dirname(__FILE__) + '/models/eventservice/events_db_base.rb'}"

#Load Event service models
Dir[File.dirname(__FILE__) + '/../lib/models/eventservice/*.rb'].each do |file|
  require "models/eventservice/#{File.basename(file, File.extname(file))}"
end

# alias for easier typing, especially in the console
TC=TestChamber
