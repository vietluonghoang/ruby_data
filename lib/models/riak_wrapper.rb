module TestChamber
  module Models
    module RiakWrapper
      attr_accessor :key
      
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      def initialize(r_object)
        @data = r_object.data
        @key = r_object.key
      end

      def id
        @key
      end

      def attribute(name)
        attribute = @data[name][0] if @data[name]
        return nil unless attribute
        # If its an array or a json blob, do one additional parse why not
        if attribute.match(/^\{|\[/)
          attribute = JSON.parse(attribute)
        elsif attribute.start_with?("^^TAPJOY_ESCAPED^^")
          attribute = attribute.gsub("^^TAPJOY_ESCAPED^^",'')
          attribute = CGI::unescape(attribute)
          JSON.parse(attribute)
        else
          attribute
        end
      end
      
      module ClassMethods
        def find(key)
          begin
            self.new(TestChamber.riak[bucket_name][key])
          rescue => e
            nil
          end
        end
      end
    end
  end
end
