module TestChamber::Creator
  class App
    module UiV2
      include UiBase
      include TestChamber::SelectFromChosen
      
      def create!
        TestChamber::Partner.act_as!(partner_id)
        visit "#{TestChamber.target_url}/dashboard/v2/apps/new?"

        # set state to "Live"
        single_nosearch_chosen_select('Live', from: 'state')

        # set platform
        single_nosearch_chosen_select(translate_platform_to_ui(platform), from: 'platform')

        fill_in("name", :with => name)
        first('.save-button').click

        ## Wait for page redirect
        find('#placements')
        id = id_from_url
      end

      def create_currency(currency_name = 'Coins')
        raise "Cannot create a new currency if app id isn't set yet" unless id
        placements_uri = URI.parse "#{TestChamber.target_url}/dashboard/v2/placements/#{id}"

        visit placements_uri unless URI.parse(page.current_url).path ==  placements_uri.path
        
        Util.wait_for(20,1) do
          # sometimes it does't go to the create currency part so try it a few times
          ele = first('a', text: 'New Currency')
          ele.click if ele
          # Wait for ajax with find
          first('input[name=name]') # returns false quickly so the whole block will try again after sleep
        end
        
        fill_in("name", :with => currency_name)

        click_button("Create")

        currency_id = find('.form-module:nth-child(2) section:nth-child(1) div').text

        unless TestChamber::UUID.uuid?(currency_id)
          raise "Failed to create virtual currency. URL was '#{current_url}'."
        end
        currency_id
      end

      # This is the same as the V1 UI as there is currently no V2 UI for creating these as of 2014-11-14
      def create_non_rewarded_currency
        visit "#{TestChamber.target_url}/dashboard/apps/#{id}/non_rewarded"
        # if the #terms_of_service checkbox isn't there, that indicates the non_rewarded
        # currency is already there.
        if el = first("#terms_of_service")
          el.click
          find_button("Setup").click
        end

        page.find('#currency_submit').trigger('click')
        Util.wait_for do
          page.find('.tapjoy-enabled').text == "Enabled"
        end
        page.find(:xpath,"//div[@id='help_nonreward_currency_id']/../../td").text
      end

      def verify_currency_create
        url = URI.parse(current_url)
        path,currency_id = url.path.split('/')[-2..-1]
        unless path == 'currencies' && TestChamber::UUID.uuid?(currency_id)
          raise "Failed to create virtual currency. Returned #{currency_id} from URL: '#{url}'."
        end

        rewarded_currency_ids << currency_id unless rewarded_currency_ids.include? currency_id
        # Persist latest currency creation for offer params access
        currency_id = currency_id
      end

      # Add the newly created app to the network specified in the constuctor's `apps_network_id`
      def add_to_apps_network
        raise "This method can only be called if apps_network_id is set" unless apps_network_id
        visit "#{TestChamber.target_url}/dashboard/tools/apps_network_association/#{apps_network_id}"
        fill_in('app_ids', :with => id)
        click_button('Add')
      end

    end
  end
end
