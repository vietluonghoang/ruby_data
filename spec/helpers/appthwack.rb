# A helper class for selecting Appthwack Devices

require 'appthwack'
require 'fuzzystringmatch'

class NoMatchError < StandardError; end

class AmbiguousMatchError < StandardError; end

##
# A container class for the data from Appthwack about a device used in a given
# test run. Appthwack returns json (converted to a hash) in the format:

# {
#  "cpu_architecture_version"=>"ARMv7",
#  "os_name"=>"android",
#  "added"=>"2014-04-30 17:51:49",
#  "large_image"=>"https://appthwack.com/appthwack/static/images/devices/large/samsung-galaxy-s5.png",
#  "name"=>"Samsung Galaxy S5",
#  "os_version"=>"4.4.2",
#  "heap_size"=>"512m",
#  "small_image"=>"https://appthwack.com/appthwack/static/images/devices/small/samsung-galaxy-s5.png",
#  "private"=>false,
#  "cpu_info"=>"2.5 GHz",
#  "os_id"=>1,
#  "form_factor"=>"phone",
#  "model"=>"galaxy s5",
#  "cpu_architecture_description"=>"ARMv7",
#  "resolution"=>"1080 x 1920",
#  "id"=>315,
#  "multiplier"=>1
# }
#
# Each key in the hash is set on the AppthwackDevice.
#
# Usage:
#   Initialize a device from config:
#   client = Appthwack::Client.new api_key
#   device = AppthwackDevice.new(client)
#
#   Or initialize a device from params:
#   device = AppthwackDevice.new(client, 'Samsung Galaxy S5', 'android', '4.4.',
#                                exact=true)
#
##

class AppthwackDevice

  # Appthwack attributes
  attr_reader :cpu_architecture_version
  attr_reader :os_name
  attr_reader :added
  attr_reader :large_image
  attr_reader :name
  attr_reader :os_version
  attr_reader :heap_size
  attr_reader :small_image
  attr_reader :private
  attr_reader :cpu_info
  attr_reader :os_id
  attr_reader :form_factor
  attr_reader :model
  attr_reader :cpu_architecture_description
  attr_reader :resolution
  attr_reader :id
  attr_reader :multiplier

  ##
  # Appthwack is rediculously specific in the strings it will accept for devices
  # so this class does some work to ensure that users can get to the right device
  # string quickly. AppthwackDevice does 3 main things:
  #
  # 1. Query the Appthwack Devices API for all the devices
  # 2. Check if the device passed in config matches any Appthwack devices.
  # 3. Perform a fuzzy search of the 'Name' and 'Model' fields in Appthwack. This
  # will automatically select a single found result above the confidence interval
  # and raise an exception for no devices or more than one device.
  ##
  def initialize(client, device=nil, os=nil, version=nil, exact=nil)
    @client = client
    @req_device = device
    @req_version = version
    @req_os = os
    @exact = exact

    matchers = [:exact_match, :fuzzy_match, :fuzzy_match_no_ver]

    matchers.each do |method|
      send method
      break if valid?
    end

    unless valid?
      raise NoMatchError, "No matches for device #{req_device}."
    end

    # Remove some private instance variables that are very verbose to make repl
    # interactions with this object nicer
    [:@devices, :@os_devices, :@client].each do |ivar|
      self.remove_instance_variable(ivar)
    end
  end

  def req_device
    @req_device ||= TestChamber::Config[:appium][:device]
  end

  def req_os
    @req_os ||= TestChamber::Config[:appium][:os]
  end

  def req_version
    @req_version ||= TestChamber::Config[:appium][:version]
  end

  def exact?
    @exact ||= TestChamber::Config[:appthwack][:device_exact]
  end

  def valid?
    @valid ||= false
  end

  private

  def devices
    @devices ||= @client.devices
  end

  def os_devices
    @os_devices ||= devices.select { |d| d["os_name"] == req_os.downcase }
  end

  def exact_match
    almost = []
    os_devices.each do |d|
      if d["name"] == req_device
        # if the version matches exactly, we're done.
        if d["os_version"] == req_version
          set_values_from_json(d)
          @valid = true
          break
        # if the version is just more specific, we're ok
        elsif d["os_version"].start_with? req_version
          almost << d
        end
      end
    end
    handle_result(almost)
  end

  ##
  # This performs a fuzzy match for a device and raises an exception if
  # there's more than one possibility or if no devices meet the threshold.
  # This uses Jaro-Winkler distance and requires a score of at least .7 to
  # consider a device 'matched'.
  #
  # Appthwack has two strings to check for a device match: Name and Model.
  # We don't check for an exact match of model, but we want to use that
  # information for the fuzzy check just to be 'extra-fuzzy'.
  #
  # Finally, we check version strings to the specificity input by the user.
  # E.g. '7.0' would be matched by both '7.0.1' and '7.0.2' but not '7'.
  ##
  def fuzzy_match(version_match: true)
    return if exact?
    matches = []
    matcher = FuzzyStringMatch::JaroWinkler.create
    os_devices.each do |d|
      catch :added do
        ["name", "model"].each do |name|
          if (matcher.getDistance(req_device, d[name]) >= 0.7 and
              version_match ? d["os_version"].start_with?(req_version) : true)
            matches << d
            # break inner loop if name matches (don't add a device twice)
            throw :added
          end
        end
      end
    end

    # if there's only 1 match and we matched the version, then use the device.
    if version_match
      handle_result(matches)
    else
      handle_result(matches, false)
    end
  end

  def fuzzy_match_no_ver
    fuzzy_match(version_match: false)
  end

  def handle_result(result, allow_only=true)
    if allow_only
      if result.length == 1
        puts "Using device #{[result.first['name'], result.first['os_version']]}."
        set_values_from_json(result.first)
        @valid = true
      elsif result.length > 1
        raise AmbiguousMatchError, "More than one match found in appthwack. " \
          "Please select from: \n" \
          "#{result.map { |r| [r["name"], r["os_version"]] }}."
      end
    else
      unless result.empty?
        raise AmbiguousMatchError, "Could not find device and version match. " \
          "Select from these device and version combinations: \n" \
          "#{result.map { |r| [r["name"], r["os_version"]] }}."
      end
    end
  end

  def set_values_from_json(match)
    @match = match
    match.each do |key, value|
      self.instance_variable_set("@#{key}", value)
    end
  end
end
