module TestChamber
  # Wrapper class for Device objects
  #
  # Some notes about how TJS handles device parameters
  #
  # When advertising_id is passed in it is normalized (lowercased and dashes removed) and used as the device identifier. The device identifier is used
  # as the leading part of the click key used to look up a click when a conversion is processed.
  # So if advertising_id is passed in as "asdf-1234" the click key will be "asdf1234.offer_id"
  #
  # If both advertising_id and udid parameters are passed into TJS, a controller filter will normalize advertising_id and set udid to
  # that same value. The original value of the udid parameter passed in will be saved in "inbound_udid" but is only used for reporting purposes.
  #
  # If only udid is passed in it is NEVER normalized. udid is just used as is.
  class Device
    include TestChamber::Rest

    attr_accessor :publisher_user_id, :mac_address, :advertising_id, :open_udid,
                  :imei, :udid, :android_id, :library_version,
                  :ad_tracking_enabled, :device_type, :install_id, :platform

    include TestChamber::OfferParams
    include TestChamber::Rest

    def self.base_url
      @base_url ||= URI("#{TestChamber.target_url}/").tap {|uri| uri.port = 5002}.to_s
    end

    def initialize(device_type: 'android',
                   display_multiplier: 1.0,
                   platform: 'android',
                   os_version: '4.4',
                   connection_type: 'wifi',
                   country_code: 'US',
                   carrier_country_code: 'us',
                   verifier: SecureRandom.hex(32),
                   carrier_name: 'tmobile',
                   mobile_country_code: '310',
                   mobile_network_code: '026',
                   language_code: 'en',
                   device_manufacturer: "Samsung",
                   device_name: "Samsung galaxy s3",
                   threatmetrix_session_id: SecureRandom.hex(16),
                   install_id: SecureRandom.hex(32),
                   timestamp: Time.now.to_i,
                   session_id: SecureRandom.hex(32),
                   publisher_user_id: SecureRandom.hex(32),
                   mac_address: (1..6).map{"%0.2X"%rand(256)}.join("").downcase,
                   advertising_id: nil,
                   open_udid: SecureRandom.uuid,
                   imei: rand(36**[14,15].sample).to_s(36),
                   android_id: SecureRandom.hex(8),
                   udid: SecureRandom.uuid,
                   library_version: '10.0.0')
      @device_type = device_type
      @display_multiplier = display_multiplier
      @platform = platform
      @os_version = os_version
      @connection_type = connection_type
      @country_code = country_code
      @carrier_country_code = carrier_country_code
      @verifier = verifier
      @carrier_name = carrier_name
      @mobile_country_code = mobile_country_code
      @mobile_network_code = mobile_network_code
      @language_code = language_code
      @threatmetrix_session_id = threatmetrix_session_id
      @timestamp = timestamp
      @session_id = session_id
      @library_version = library_version
      @device_location = "true"
      @library_revision = "82661d"
      @plugin = "native"
      @screen_density = "240"
      @screen_layout_size = "2"
      @sdk_type = "event"
      @store_view = "true"
      @install_id = install_id
      # Any time udid is used as the device identifier it is not normalized
      # UDID is always just taken as is. So we normalize it here so that
      # if this is used as the device identifier we can always assume that
      # the device identifier is normalized when we look up the click
      @udid = self.class.normalize(udid)
      @device_name = device_name
      @device_manufacturer = device_manufacturer
      @open_udid = open_udid
      @publisher_user_id = publisher_user_id
      @mac_address = mac_address
      @advertising_id = self.class.normalize(advertising_id)
      @android_id = android_id if platform == "android"
      @imei = imei if platform == "ios"
      @opted_out = false
    end

    # Creates a device with the given attributes.  Note that this will create a
    # device in the v2 DIS API.  The v1 API does not expose +create+
    # functionality directly.
    def create(params = {})
      rest_request(:post, "#{self.class.base_url}api/v2/devices", payload: query_params.merge(params))
      true
    end

    def query_params
      Hash[instance_variables.map(&:to_s).map {|iv| iv.gsub('@', '') }.zip(instance_variables.map {|iv| self.instance_variable_get(iv) })]
    end

    def offer_params
      query_params.merge({
        'gamer_id' =>  'fc053cb7-cc6d-4c47-af55-dde62d7fed83', # TODO what is a good value for this? Device_id?
        'hide_premium' => 'false',
        'source' => 'offerwall'
      })
    end

    # After we gather the params from the mapping we need to remove some identifiers based on the SDK version
    # This is to ensure the click key generation can match how Connect works. This is necessary as avertising_id
    # can supercede all other identifiers and Offer#click_key will always use the SDK supported ID.
    def params_for(*args)
      params = super(*args)

      remove_keys = [:publisher_user_id, :udid, :advertising_id] - [normalized_id_attribute]
      remove_keys.each { |key| params.delete(key) }

      return params
    end

    def normalized_id
      id = send(normalized_id_attribute)
      raise "there was no id for this library version #{@library_version}" unless id
      self.class.normalize(id)
    end

    def normalized_id_attribute
      case @library_version
      when "9.1.4"  then :publisher_user_id
      when "10.0.0" then :udid
      when "10.1.0" then :advertising_id
      when "10.1.1" then :advertising_id
      else               :advertising_id
      end
    end

    # Builds a publisher user represented by this device in the given app.  The
    # user's unique identifier will be determined by one or more attributes
    # in this device.  See PublisherUser for more information.
    def publisher_user(app)
      PublisherUser.new(:app => app, :device => self)
    end

    # NB: there's no reverse operation (to opt back in) because PM
    # isn't interested in supporting that feature.
    def opt_out

      device_id = nil
      id_type = nil
      if(@advertising_id)
        device_id = @advertising_id
      elsif(@udid)
        device_id = @udid
      elsif(@mac_address)
        device_id = @mac_address
      end

      # Default arg for ip_address because it's not relevant to
      #  testing (it's simply persisted) and it makes the interface cleaner
      args = "device_id=#{device_id}&ip_address=127.0.0.1"
      opt_out_url = "#{TestChamber.target_url}/v1/opt_out/oo?#{args}"

      response = rest_request(:get, opt_out_url)
      @opted_out = true if response[:status] == 200
    end

    # Class methods for returning devices of various configurations
    class << self
      def android_9_point_1_point_4(publisher_user_id: true,
                                    android_id: false,
                                    mac_address: false,
                                    udid: true,
                                    **opts)
        TestChamber::Device.new(opts.merge(library_version: '9.1.4')).tap do |device|
          if publisher_user_id.is_a? String
            device.publisher_user_id = publisher_user_id
          end
          device.publisher_user_id = nil unless publisher_user_id

          # The method defaults several named params to a boolean value, and
          # does not include them in the options sent upon device creation.
          # In order to pass these params as a string to this method, this line
          # sets the android_id to a string when a string is passed, otherwise
          # it expects a boolean.  This applies to mac_address and udid as well
          device.android_id = android_id if android_id.is_a? String
          device.android_id = nil unless android_id

          device.mac_address = mac_address if mac_address.is_a? String
          device.mac_address = nil unless mac_address

          device.udid = udid if udid.is_a? String
          device.udid = nil unless udid
        end
      end

      def android_10_point_0(open_udid: false, **opts)
        android_9_point_1_point_4(opts).tap do |device|
          device.library_version = "10.0.0"
          device.open_udid = open_udid if open_udid.is_a? String
          device.open_udid = nil unless open_udid
        end
      end

      def android_10_point_1(ad_tracking_enabled: false, **opts)
        android_10_point_0(opts).tap do |device|
          device.library_version = "10.1.0"
          device.advertising_id = normalize(SecureRandom.uuid)
          device.ad_tracking_enabled = ad_tracking_enabled
        end
      end

      def android_10_point_1_point_1(disable_persistent_ids: false, **opts)
        android_10_point_1(opts).tap do |device|
          device.library_version = "10.1.1"
          if disable_persistent_ids
            device.android_id = nil
            device.mac_address = nil
            device.udid = nil
          end
        end
      end

      def ios
        TestChamber::Device.new(platform: "ios",
                                device_type: "ios",
                                device_manufacturer: "Apple",
                                device_name: "iPhone",
                                os_version: "7.1",
                                library_version: "10.0.0")
      end

      def normalize(id)
        id.gsub('-', '').downcase if id
      end
    end

  end
end
