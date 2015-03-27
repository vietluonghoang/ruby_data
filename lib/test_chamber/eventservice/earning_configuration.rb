require 'active_support/core_ext/hash'

module TestChamber
  module EventService
    class EarningConfiguration
      include Capybara::DSL
      include TestChamber::Rest
      include SelectFromChosen

      attr_reader :ad_type
      attr_reader :demand_types
      attr_reader :video_autoplay
      attr_reader :video_timer_delay
      attr_reader :hide_video_close_button
      attr_reader :currency_id
      attr_reader :test_offer_id
      attr_reader :segment
      attr_reader :bid_controls


      def initialize(options = {})
        defaults = {
          :ad_type                 => 'featured',
          :demand_types            => ['All'],
          :video_autoplay          => true,
          :video_timer_delay       => 4,
          :hide_video_close_button => true,
          :test_offer_id           => '',
          :segment                 => 'All Users',
          :bid_controls            => nil,
        }

        options = defaults.merge(options)

        # called out for readability
        unless @app_id = options[:app_id]
          raise "app_id must be provided to set an Earning Configuration!"
        end

        unless @partner_id = options[:partner_id]
          raise "partner_id must be provided to set an Earning Configuration!"
        end

        # called out for readability
        unless @currency_id = options[:currency_id] || @app_id
          raise "currency_id must be provided to set an Earning Configuration!"
        end

        # called out for readability
        unless @placement_id = options[:placement_id]
          raise "placement_id must be provided to set an Earning Configuration!"
        end

        @ad_type                 = options[:ad_type] || "featured"
        @enabled                 = options[:enabled]
        @demand_types            = options[:demand_types]
        @video_autoplay          = options[:video_autoplay]
        @video_timer_delay       = options[:video_timer_delay].to_i
        @hide_video_close_button = options[:hide_video_close_button]
        @test_offer_id           = options[:test_offer_id]
        @segment_id              = options[:segment_id]
        @bid_controls            = options[:bid_controls]
        @placement_id            = options[:placement_id]
        @id                      = options[:id]

        Partner.act_as!(@partner_id, api: true)

        set_values!
        self
      end

      def update_values!(options)
        @ad_type                 = options[:ad_type]
        @enabled                 = options[:enabled]
        @demand_types            = options[:demand_types]
        @video_autoplay          = options[:video_autoplay]
        @video_timer_delay       = options[:video_timer_delay].to_i
        @hide_video_close_button = options[:hide_video_close_button]
        @test_offer_id           = options[:test_offer_id]
        @segment_id              = options[:segment_id]
        @bid_controls            = options[:bid_controls]
        set_values!
      end

      def set_values!
        rule_params = {
          enabled:                 @enabled,
          ad_type:                 @ad_type,
          demand_types:            @demand_types,
          video_autoplay:          @video_autoplay,
          video_timer_delay:       @video_timer_delay,
          hide_video_close_button: @hide_video_close_button,
          test_offer_id:           @test_offer_id,
          segment_id:              @segment_id,
          bid_controls:            @bid_controls,
        }.compact

        ec_payload = {
          rule: rule_params,
          app_id:       @app_id,
          placement_id: @placement_id,
          partner_id:   @partner_id,
          format:       'json'
        }.compact

        authenticated_request(
          :put,
          "api/client/apps/#{@app_id}/placements/#{@placement_id}/rules/#{@id}/ccc",
          payload: ec_payload
        )
      end

      def get_json
        response = authenticated_request(
          :get,
          "api/client/apps/#{@app_id}/placements/#{@placement_id}/rules/#{@id}"
        )
        JSON.parse(response[:body])["result"]["rule"]
      end
    end
  end
end
