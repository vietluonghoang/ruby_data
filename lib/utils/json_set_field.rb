module TestChamber
  module JsonSetField
    def self.included(base)
      base.extend(ClassMethods)
      base.before_save Wrapper.new
      base.after_save Wrapper.new
      base.after_initialize Wrapper.new
    end

    module ClassMethods
      def json_set_fields
        @json_set_fields ||= Array.new
      end

      def json_set_field(*fields)
        @json_set_fields = json_set_fields + fields
      end
    end

    class Wrapper
      def before_save(record)
        record.class.json_set_fields.each do |field|
          record.send("#{field}=", record.send(field).to_json)
        end
      end

      def after_save(record)
        record.class.json_set_fields.each do |field|
          val = begin
                  JSON.parse(record.send(field)).to_set
                rescue
                  Set.new
                end
          record.send("#{field}=", val)
        end
      end

      alias_method :after_initialize, :after_save
    end
  end
end

ActiveRecord::Base.send(:include, TestChamber::JsonSetField)
