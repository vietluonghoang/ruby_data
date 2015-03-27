module TestChamber::Creator
  class App
    module UiV1
      include TestChamber::Creator::App::UiBase

      def create!
        TestChamber::Partner.act_as!(partner_id)
        visit "#{TestChamber.target_url}/dashboard/apps/new"

        # Sometimes when we create an app clicking the Add App button ends us up back on the new app page.
        # retry to see if that helps
        retries = 2
        begin
          select("Live", :from => "state")
          select(translate_platform_to_ui(platform), :from => "app[platform]")
          # Only applies for ios apps
          select("US", :from => "app_country") if platform == 'iOS'
          fill_in('app[name]', :with => name)
          Util.trigger_click('#app_submit')

          self.id = id_from_url
        rescue Capybara::ElementNotFound => e
          if (retries -= 1).zero?
            raise e
          else
            puts "App Add failed with exception #{e}. Let's try again"
            retry
          end
        end
      end

      def create_currency(currency_name = 'Coins')
        raise "Cannot create a new currency if app id isn't set yet" unless id
        visit "#{TestChamber.target_url}/dashboard/apps/#{id}/currencies/new"

        fill_in('currency[name]', :with => currency_name)
        check('terms_of_service') if first('#terms_of_service')

        # sometimes we miss the click. Try it a few times to make sure.
        # This will create the currency, edit form is still not present
        Util.trigger_click('#currency_submit') do
          first("#currency_conversion_rate")
        end

        Util.wait_for(10,1) do
          verify_currency_create
        end

        # Virtual currency edit form is now presented, ensure it's enabled
        check('currency_tapjoy_enabled')

        if rev_share_override
          Util.wait_for(10, 1) do
            fill_in('currency[rev_share_override]', with: rev_share_override)
            first('#currency_rev_share_override').value == rev_share_override.to_s
          end
        end

        Util.trigger_click('#currency_submit')

        id_from_url
      end

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
        true
      end

      # Add the newly created app to the network specified in the constuctor's `apps_network_id`
      def add_to_apps_network
        visit "#{TestChamber.target_url}/dashboard/tools/apps_network_association/#{apps_network_id}"
        fill_in('app_ids', :with => id)
        click_button('Add')
      end
    end
  end
end
