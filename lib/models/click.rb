require 'models/riak_wrapper'
module TestChamber
  module Models
    class Click
      include TestChamber::Models::RiakWrapper
      class << self
        def bucket_name
          "clicks"
        end

        def format_click_key(device_key, offer)
          key = case offer
          when TestChamber::GenericOffer
            Digest::MD5.hexdigest("#{device_key}.#{offer.id}")
          else
            "#{device_key}.#{offer.id}"
          end
        end
      end
    end
  end
end
