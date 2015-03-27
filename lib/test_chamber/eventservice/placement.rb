#1. Create placements basic
#2. switch placements on - off
#3. placement monetization-settings
# => Adtype
#  => FSI
#    => demand type
#    => autoplay video
#    => hide close button
#  => Video
# => currency options
# => segment selection
#4. placement messaging settings
# => segement selection
# => message window

module TestChamber
 module EventService
  class Placement
    include UniqueName
    include SelectFromChosen
    include Capybara::DSL
    include TestChamber::Rest

    attr_reader :display_name
    attr_reader :event_name
    attr_reader :event_value
    attr_reader :context
    attr_reader :id

    CONTEXT_MAP = { "Achievement" => "achievement", "Failure" => "failure", "User Pause" => "user_pause", "App Launch" => "app_launch" }

    def initialize(options = {})
      raise 'app_id must be provided to create a Placement!' if options[:app_id].nil?
      raise 'partner_id must be provided to create a Placement!' if options[:partner_id].nil?
      name = "test-chamber-event_#{name_datestamp}"
      defaults = {
        :name => name,
        :value => nil,
        :context => "User Pause",
        :create_via_ui => false
      }

      @options      = defaults.merge(options)

      if @options[:create_via_ui]
        <<-eos
        ---WARNING---
        Creating via the UI is unstable and does not always work. For best
        results, use the API methods
        eos
      end
      @event_name   = @options[:name]
      @event_value  = @options[:value]
      @display_name = @options[:display_name] || @options[:name]
      @context      = @options[:context] || "User Pause"
      @app_id       = @options[:app_id]
      @partner_id   = @options[:partner_id]

      create!
    end

    def context_value
      CONTEXT_MAP[@context]
    end

    def create!
      Partner.act_as!(@partner_id, api: !@options[:create_via_ui])

      if @options[:create_via_ui]
        visit "#{TestChamber.target_url}/dashboard/v2/placements/#{@app_id}"

        find_link('New Event')
        click_link('New Event')

        Util.wait_for(5,1) do
          first("input[name='name']")
        end

        fill_in('name', :with => @event_name)
        fill_in('value', :with => @event_value)
        fill_in('display_name', :with => @display_name)
        single_nosearch_chosen_select(@moment, :from => 'context') if @moment
        Util.trigger_click(find(:css,'.saveButton',:visible => true))

        if page.has_content?(@display_name)
          set_id_from_dom
        else
          raise "event #{@event_name} not created"
        end
      else
        placement_payload = {
          placement: {
            event_name:   @event_name,
            display_name: @display_name,
            event_value:  @event_value,
            partner_id:   @partner_id,
            app_id:       @app_id,
            context:      context_value
          },
          app_id: @app_id,
          format: 'json'
        }
        response = authenticated_request(
          :post,
          "api/client/apps/#{@app_id}/placements",
          payload: placement_payload
        )
        placement = JSON.parse(response[:body])["result"]["placement"]
        @id = placement["id"]
        @earning_configuration_id = placement["earning_configuration"]["id"]
      end
    end

    def earning_configuration_id
      @earning_configuration_id
    end

    private

    def enable
      raise "enable should be implemented by derived classes"
    end

    def disable
      raise "disable should be implemented by derived classes"
    end

    def set_id_from_dom
      evt_node = page.find(:xpath,"//h5[contains(text(),'#{@display_name}')]")
      # "../.." traverses up the tree, just in case anyone was wondering
      @id = evt_node.find(:xpath,"../..").find(:xpath,"../..").find(:css,'input[type="checkbox"]').value
    end
  end

  class MonetizationPlacement < Placement
    def initialize(options = {})
      super(options)
    end

    def enable
      if @options[:create_via_ui]
        on_toggle_id = "toggle-#{@id}-on"
        page.execute_script("$(\"\##{on_toggle_id}\").trigger(\"click\")")
        #  Async call alert: only proceed once completed.
        #  I would prefer a waiting capybara call, but this does not change any css
        arbitary_sleep(1)
        return true if is_radio_checked?(on_toggle_id)
        raise "Failed to enable placement #{@event_name}"
      else
        ec_payload = {
          rule: {
            enabled: true
          },
          placement_id: @id,
          partner_id:   @partner_id,
          format:       'json'
        }
        response = authenticated_request(
          :put,
          "api/client/apps/#{@app_id}/placements/#{@id}/rules/#{@earning_configuration_id}",
          payload: ec_payload
          )
        JSON.parse(response[:body])["result"]["rule"]["enabled"] == true
      end
    end

    def disable
      if @options[:create_via_ui]
        off_toggle_id = "toggle-#{@id}-off"
        page.execute_script("$(\"\##{off_toggle_id}\").trigger(\"click\")")
        arbitary_sleep(1)
        return true if is_radio_checked?(off_toggle_id)
        raise "Failed to disable placement #{@event_name}"
      else
        ec_payload = {
          rule: {
            enabled: false
          },
          placement_id: @id,
          partner_id:   @partner_id,
          format:       'json'
        }
        response = authenticated_request(
          :put,
          "api/client/apps/#{@app_id}/placements/#{@id}/rules/#{@earning_configuration_id}",
          payload: ec_payload
        )
        JSON.parse(response[:body])["result"]["rule"]["enabled"] == false
      end
    end

    private

    def arbitary_sleep(secs)
      sleep(secs)
    end

    def is_radio_checked?(radio_id)
      page.evaluate_script("$(\"##{radio_id}\").is(\":checked\")")
    end
  end

  class MessagingPlacement < Placement
    def initialize(options = {} )
      super(options)
    end

    def enable
      true
    end

    def disable
      true
    end
  end
 end
end
