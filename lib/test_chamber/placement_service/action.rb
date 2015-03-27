module TestChamber
  module PlacementService
    class Action
      include UniqueName
      extend  TestChamber::Rest

      BASE_URL = "#{TestChamber.target_url}/placement_service/v1/"

      ActionParams = %w(enabled name description target impression_total
                      impression_interval_unit from_when until_when
                      source_type placement_ids)

      def initialize(options = {})
        raise "App id is a required parameter" if options[:app_id].blank?
        raise "source_type is a required parameter" if options[:source_type].blank?

        name        = "test-chamber-placement_action_#{name_datestamp}"
        description = "test chamber description #{name}"

        defaults = {
          name: name,
          description: description,
          enabled: false
        }

        @options      = defaults.merge(options)
        @options.each do | opt , value |
          instance_variable_set("@#{opt}", value)
        end
      end

      def payload
        @options
      end

      class << self
        def post(options={})
          url = "#{BASE_URL}apps/#{options[:app_id]}/actions"
          response = authenticated_request(:post, url, payload: options)
          [response[:status], JSON.parse(response[:body])]
        end

        def get(options = {})
          url = "#{BASE_URL}apps/#{options[:app_id]}/actions"

          if options[:action_id].present?
            url = "#{url}/#{options[:action_id]}"
          end

          response = authenticated_request(:get, url)
          [response[:status], JSON.parse(response[:body])]
        end

        def put(options = {})
          url = "#{BASE_URL}apps/#{options[:app_id]}/actions/#{options[:action_id]}"
          params = options.except(:app_id,:action_id)
          response = authenticated_request(:put, url, payload: params)
          [response[:status], JSON.parse(response[:body])]
        end

        def delete(options={})
          url = "#{BASE_URL}apps/#{options[:app_id]}/actions/#{options[:action_id]}"
          response = authenticated_request(:delete, url)
          [response[:status]]
        end
      end
    end

    class AdAction < Action
      AdParams = %w(ad_type currency_id frequency video_autoplay_timer
                  hide_video_close_button autoplay_video demand_types bid_controls)

      def initialize(options = {})
        options[:source_type] = 'ad'
        super
      end
    end

    class MmAction < Action
      MmParams = %w(mm_type campaign_id)
      def initialize(options = {})
        options[:source_type] = 'mm'
        super
      end
    end
  end
end


