require 'models/riak_wrapper'
module TestChamber
  module Models
    class PointPurchase
      include TestChamber::Models::RiakWrapper
      def self.bucket_name
        "point_purchases"
      end 
    end
  end
end
