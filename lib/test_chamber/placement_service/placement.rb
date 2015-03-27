module TestChamber
  module PlacementService
    class Placement
      include UniqueName
      extend TestChamber::Rest

      BASE_URL = "#{TestChamber.target_url}/placement_service/v1/"

      attr_reader :name
      attr_reader :description
      attr_reader :category
      attr_reader :type
      attr_reader :id

      CATEGORY_MAP = { "Achievement" => "achievement", "Failure" => "failure", "User Pause" => "user_pause", "App Launch" => "app_launch" }

      def initialize(options = {})
        raise "App id is a required parameter" if options[:app_id].blank?
        name        = "test-chamber-placement_#{name_datestamp}"
        description = "test chamber description #{name}"

        defaults = {
          name: name,
          description: description,
          category: "user_pause",
          placement_type: 'contextual'
        }

        @options      = defaults.merge(options)

        @name        = options[:name]
        @description = options[:description]
        @category    = options[:category]
        @app_id      = options[:app_id]
        @type        = options[:placement_type]
      end

      def payload
        @options
      end

      class << self
        def post(options={})
          url = "#{BASE_URL}apps/#{options[:app_id]}/placements"
          params = options.except(:app_id)
          response = authenticated_request(:post, url, payload: params)
          [ response[:status], JSON.parse(response[:body]) ]
        end

        def get(options = {})
          url = "#{BASE_URL}apps/#{options[:app_id]}/placements"

          if options[:placement_id].present?
            url = "#{url}/#{options[:placement_id]}"
          end

          response = authenticated_request(:get, url)
          [ response[:status], JSON.parse(response[:body]) ]
        end

        def put(options = {})
          url = "#{BASE_URL}apps/#{options[:app_id]}/placements/#{options[:placement_id]}"
          params = options.except(:app_id,:placement_id)
          response = authenticated_request(:put, url, payload: params)
          [ response[:status], JSON.parse(response[:body]) ]
        end

        def delete(options={})
          url = "#{BASE_URL}apps/#{options[:app_id]}/placements/#{options[:placement_id]}"
          response = authenticated_request(:delete, url)
          [ response[:status] ]
        end
      end
    end
  end
end

