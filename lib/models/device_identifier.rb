require 'models/riak_wrapper'
module TestChamber
  module Models
    class DeviceIdentifier
      include TestChamber::Models::RiakWrapper
      def self.bucket_name
        "device_identifiers"
      end 
    end
  end
end
