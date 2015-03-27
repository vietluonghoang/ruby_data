require 'models/riak_wrapper'
module TestChamber
  module Models
    class PublisherUser
      include TestChamber::Models::RiakWrapper
      def self.bucket_name
        "publisher_users"
      end 
    end
  end
end
