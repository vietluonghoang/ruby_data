
# Rake task for interacting with the fake OptSOA service in your TIAB
# All of these tasks can take two device related environment variables both of which
# are optional.
#
# create_device: boolean, if true the task will create a new device with a random UDID
#   this device will be used for the related request to fake OptSOA.  The device UDID
#   will be passed to standard output for reference/usage.  Defalut is false
#
# device_id: UDID string, if this is provided it will be used as the device_id for the
#   related request to fake OptSOA.  The default for this is ':all' which will register
#   a response which fake OptSOA returns for unregistered devices

# This will create a new device and set it as test_chambers current device
# If no device_id is provided and 'create_device' is falsey it will not create
# a device.

def set_current_device
  return false if ENV['create_device'].nil? && ENV['device_id'].nil?
  device_id = fetch_variable('device_id')

  TestChamber::Device.new.tap do |device|
    device.udid = device_id if device_id
    TestChamber.current_device = device
    puts "Using device with ID: #{device.udid}"
  end
end

# Get a variable by name from the environment.
# If required is true and the variable is not found (nil) an error is raised
def fetch_variable(var_name, required: false)
  raise "#{var_name} is a required variable" if ENV[var_name].nil? && required

  return false if ENV[var_name] && ENV[var_name].downcase == 'false'
  ENV[var_name]
end

namespace :opt_soa do

  # we put this here so we can call it from each task. We can't put it at the top because
  # if we set TC_NO_LOGIN in the rake task it is set as the tasks are parsed and then is always
  # set when spec_helper is loaded for all other rake tasks.
  # It should be required by all tasks below
  task :require_things do
    ENV['TC_NO_LOGIN'] = "true"
    ENV['TC_NO_BROWSER'] = "true"
    require 'spec_helper'
  end

  
  desc "Inject a custom request to fake Opt SOA using the env. var 'response'"
  task :put_response => :require_things do
    response = YAML.load(fetch_variable("response", required: true))
    puts response.class

    if set_current_device
      TestChamber::OptSOA.set_response response
    else
      TestChamber::OptSOA.set_response response, device_id: :all
    end

  end

  desc "Inject offers to be returned at first from fake Opt SOA using the env. var 'offer_ids' which should be a comma separated list '3,4,5'"
  task :put_top_offers => :require_things do
    # Offer id's should be a comma separated list: offer_ids=3,4,5
    offer_ids = fetch_variable("offer_ids", required: true).split(',')

    if set_current_device
      TestChamber::OptSOA.set_top_offers offer_ids
    else
      TestChamber::OptSOA.set_top_offers offer_ids, device_id: :all
    end

  end

  desc "Inject offers to be returned from fake Opt SOA using the env. var 'offer_ids' which should be a comma separated list '3,4,5'"
  task :put_offers => :require_things do
    # Offer id's should be a comma separated list: offer_ids=3,4,5
    offer_ids = fetch_variable("offer_ids", required: true).split(',')

    if set_current_device
      TestChamber::OptSOA.set_only_offers offer_ids
    else
      TestChamber::OptSOA.set_only_offers offer_ids, device_id: :all
    end
  end

  desc "Have fake Opt SOA return a random collection of enabled offers for all devices by default.
Set the country targeting to always include VN and US so testing can be done without messing with geoip filtering"
  task :serve_random_enabled_offers => :require_things do
    puts "Fetching all enabled offers..."

    # any enabled offers with country targeting enabled
    offers = TestChamber::Models::Offer.where("tapjoy_enabled = ? AND user_enabled = ? AND countries != ?", true, true, '' )
    # anything with country targetting, let US and VN see them all
    puts "Updating all offers with country targeting to target US and VN for testing"
    offers.update_all(countries: "[\"US\",\"VN\"]")
    
    # just take 1000 as tjs filters them all so loading more makes offerwall even slower

    offer_ids = offers.shuffle.slice(0,1000).map(&:id)
    puts "Randomizing offers and loading them into fake OptSOA..."

    TestChamber::OptSOA.set_top_offers offer_ids, device_id: :all
  end

end
