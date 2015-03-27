require 'models/riak_wrapper'
module TestChamber
  module Models
    class Device
      include TestChamber::Models::RiakWrapper
      def self.bucket_name
        "d"
      end 
    end
  end
end
