require 'models/riak_wrapper'
module TestChamber
  module Models
    class Reward
      include TestChamber::Models::RiakWrapper
      def self.bucket_name
        "rewards"
      end 
    end
  end
end
