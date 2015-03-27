require 'securerandom'

class ConnectRequestData
  class << self
    def deep_duplicate(obj)
      # I could not find a sane way to deep copy something like a hash without reference copying
      Marshal.load(Marshal.dump(obj))
    end

    def android_9_point_1_point_4_request(opts={})
      to_merge = opts.delete(:to_merge) {{}}
      params = core_android_connect_request(opts).merge(to_merge).tap do |hsh|
        hsh[:install_id]         =  install_id
        hsh[:library_version]    =  "9.1.4"
        # generate publisher user ID if flag is set, otherwise default to the logic chain here
        hsh[:publisher_user_id]  =  opts[:publisher_user_id] ? publisher_user_id : hsh[:android_id] || hash[:mac_address] || hsh[:udid]
      end
      deep_duplicate(params)
    end

    def android_10_point_0_request(opts={})
      to_merge = opts.delete(:to_merge) {{}}
      params = android_9_point_1_point_4_request(opts).merge(to_merge).tap do |hsh| 
        hsh[:install_id]        =  install_id
        hsh[:library_version]   =  "10.0.0"
        hsh[:open_udid]         =   open_udid if opts[:open_udid]
        # We stopped providing a make-shift value at this point, so remove it if we didn't actually desire one
        hsh.delete(:publisher_user_id) unless opts[:publisher_user_id]
      end
      deep_duplicate(params)
    end

    def android_10_point_1_request(opts={})
      to_merge = opts.delete(:to_merge) {{}}
      params = android_10_point_0_request(opts).merge(to_merge).merge({ 
        :ad_tracking_enabled  =>  opts[:ad_tracking_enabled] || "false",
        :advertising_id   =>  advertising_id,
        :library_version      =>  "10.1.0"
                                                                      })
      deep_duplicate(params)
    end

    def android_10_point_1_point_1_request(opts={})
      to_merge = opts.delete(:to_merge) {{}}
      params = android_10_point_1_request(opts).merge(to_merge).tap do
        if opts[:disable_persistent_ids]
          hsh.delete(:android_id)
          hsh.delete(:udid)
          hsh.delete(:mac_address)
        end
      end
      deep_duplicate(params)
    end

    def version
      (1..[3,4].sample).map { rand(10) }.join('.')
    end

    def country_code
      "US"
    end

    def carrier_country_code
      "us"
    end

    def verifier
      SecureRandom.hex(32)
    end

    def carrier_name
      "tmobile"
    end

    def mobile_country_code
      "310"
    end

    def mobile_network_code
      "026"
    end


    def language_code
      "en"
    end

    def threatmetrix_session_id
      SecureRandom.hex(16)
    end

    def install_id
      SecureRandom.hex(32)
    end

    def timestamp
      Time.now.to_i
    end

    def android_id
      SecureRandom.hex(8)
    end

    def publisher_user_id
      SecureRandom.hex(32)
    end

    def session_id
      SecureRandom.hex(32)
    end

    def mac_address
      # We don't want the : between groupings
      (1..6).map{"%0.2X"%rand(256)}.join("").downcase
    end

    def advertising_id
      SecureRandom.uuid
    end

    def open_udid
      SecureRandom.uuid
    end

    def imei
      rand(36**[14,15].sample).to_s(36)
    end

    def udid(type)
      case type
      when :imei
        imei
      when :mac_address
        mac_address
      else
        SecureRandom.hex(20)
      end 
    end

    private

    def core_ios_connect_request(opts={})
      # Review this for casing
      core_connect_request(opts).merge({
        :platform             =>  "ios",
        :device_type          =>  "ios",
        :device_manufacturer  =>  "Apple",
        :device_name          =>  "iPhone",
      })
    end

    def core_android_connect_request(opts={})
      core_connect_request(opts).merge({
        :android_id           =>  android_id,
        :platform             =>  "android",
        :device_type          =>  "android",
        :device_manufacturer  =>  "Samsung",
        :device_name          =>  "Samsung galaxy s3",
        :os_version           => "4.4"
      })
    end

    def core_connect_request(opts={})
      {}.tap do |hsh|
        hsh[:app_version]           = version
        hsh[:bridge_version]        = version # I don't think this matters at all
        hsh[:carrier_country_code]  = carrier_country_code
        hsh[:carrier_name]          = carrier_name
        hsh[:connection_type]       = "wifi"
        hsh[:country_code]          = country_code
        hsh[:device_location]       = "true"
        hsh[:display_multiplier]    = "1.0"
        hsh[:language_code]         = language_code
        hsh[:library_revision]      = "826621d"
        hsh[:mac_address]           = mac_address
        hsh[:mobile_country_code]   = mobile_country_code
        hsh[:mobile_network_code]   = mobile_network_code
        hsh[:os_version]            = version, # I don't think this really matters at all.
        hsh[:publisher_user_id]     = publisher_user_id if opts[:publisher_user_id]
        hsh[:plugin]                = "native"
        hsh[:screen_density]        = "240"
        hsh[:screen_layout_size]    = "2"
        hsh[:sdk_type]              = "offers"
        hsh[:session_id]            = session_id
        hsh[:store_view]            = "true"
        hsh[:threatmetrix_session_id]   = threatmetrix_session_id
        hsh[:timestamp]             = timestamp
        hsh[:udid]                  = udid(opts[:udid_type])
        hsh[:verifier]              = verifier
      end
    end
  end
end
