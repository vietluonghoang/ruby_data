module TestChamber
  # Provides edit method that can be used by an editor module and various
  # helper methods shared between objects that interact with the UI
  module UiBehavior

    def self.included(klass)
      klass.class_eval { include TestChamber::SelectFromChosen }
    end

    # Edit implementation that visits the objects #edit_url, populates and
    # submits the form.
    # @param [TestChamber::Properties] properties A properties object used to populate the
    #   edit form
    def edit!(properties)
      visit edit_url
      populate_offer_form(properties)
      # the edit dashboard is really not user friendly...
      # you have to check the featured input and submit the form
      # ... then you have to attach the image and submit again
      if properties.featured
        submit_form
        visit edit_url
        populate_offer_form(properties)
      end
      submit_form
    end

    # Submit the edit form, searching for an input named 'commit'
    # @param [Boolean] validate_redirect (true) If true the method will validate a
    #   redirect occurred after submission
    def submit_form(validate_redirect: true)
      update_button = find("#offer_submit[name='commit']")
      if update_button.nil?
        raise 'Unable to find the Update or Save Changes button on the edit offers page'
      end
      update_button.click
      # Ensure the offer saved and we are no longer on the edit page
      find('a', text: '[Edit Offer]') if validate_redirect
    end

    # Use the provided properties to populate edit form fields.  Only non-nil
    # properties will be used.
    # @param [TestChamber::Properties] properties
    def populate_offer_form(properties)
      if properties.bid
        update_bid(properties.bid)
        find('div#help_bid').click
        # The logic of when this dialog appears and doesn't is very mysterious.
        # It appears to always be there above $5 but it depends on the offer type.
        # I hate sleeps but that appears to be the only way to do this where we give
        # the js on the page enough time to trigger the modal if its going to.
        sleep 1
        Util.trigger_click("#cboxAccept") if first("#cboxAccept", visible: true)
      end

      find('#offer_tapjoy_enabled').set(properties.tapjoy_enabled) unless properties.tapjoy_enabled.nil?
      find('#offer_user_enabled').set(properties.user_enabled) unless properties.user_enabled.nil?
      find('#offer_self_promote_only').set(properties.self_promote_only) unless properties.self_promote_only.nil?

      update_device_types(properties.device_types) if properties.device_types
      update_target_os_versions(properties.target_os_versions) if properties.target_os_versions
      update_connection_type(properties.connection_type) if properties.connection_type

      unless properties.allow_negative_balance.nil?
        find(:css, '#offer_allow_negative_balance').set(properties.allow_negative_balance)
      end
      select(properties.objective_id, from: 'offer[offer_objective_id]') if properties.objective_id

      find(:css, '#offer_offerwall').set(properties.allow_on_offerwall) unless properties.allow_on_offerwall.nil?
      find(:css, '#offer_featured').set(properties.featured) unless properties.featured.nil?
      unless properties.featured_ad_action.nil?
        fill_in('offer_featured_ad_action', with: properties.featured_ad_action)
      end
      unless properties.featured_ad_content.nil?
        fill_in('offer_featured_ad_content', with: properties.featured_ad_content)
      end
      if properties.featured && first(:id, 'tr_video_preview_preview_img')
        show_input = "document.getElementById('video_preview_preview_img').className = ''";
        hide_input = "document.getElementById('video_preview_preview_img').className = 'hidden'";
        page.execute_script(show_input)
        attach_file('video_preview_preview_img', properties.preview_path)
        page.execute_script(hide_input)
      end
      find(:css, '#offer_premium').set(properties.premium) unless properties.premium.nil?
      find(:css, '#offer_multi_complete').set(properties.multi_complete) unless properties.multi_complete.nil?
      select('Pay-Per-Click on Instruction Page', from: 'offer_pay_per_click') if properties.ppi_instructions

      unless properties.require_admin_device.nil?
        find("#offer_requires_admin_device[value='1']").set(properties.require_admin_device)
      end

      select(properties.direct_pay, from: 'offer[direct_pay]') if properties.direct_pay

      fill_in('offer[name]', with: properties.name) if properties.name
      fill_in('offer[title]', with: properties.title) if properties.title
      fill_in('offer[details]', with: properties.details) if properties.details
      fill_in('offer[name_suffix]', with: properties.name_suffix) if properties.name_suffix

      if properties.supported?(:compound_template_url) && properties.compound_template_url
        all('#offer_compound_supported')[1].set(true) # hack due to two elements having same id
        find('#compound_template_url').set(properties.compound_template_url) if properties.compound_template_url
      end

      update_icon(settings.icon_path) if properties.icon_path
      update_moments(properties.moments) if properties.moments
      update_icon(properties.icon_path) if properties.icon_path

    end

    # Update the bid field and if the bid is below 2 cents, update the
    # monetary_min_bid_override field
    # @param (Fixnum) bid
    def update_bid(bid)
      fill_in('offer[monetary_bid]', :with => bid.to_s)
      if bid.to_f < 0.02
        fill_in('offer[monetary_min_bid_override]', :with => bid.to_s)
        submit_form(validate_redirect: false)
        visit edit_url
      end

    end

    # Update the icon image with a new file
    # @param (String) icon_path
    def update_icon(icon_path)
      within_frame(find(:css, '#icon_upload')) do
        find('#offer_upload_icon').set(File.absolute_path(icon_path))
        click_button 'upload_button'
      end
    end

    # Update the device types chosen field with the provided array
    # @param [Array(Symbol)] device_types
    def update_device_types(device_types)
      device_types = JSON.parse(device_types) if device_types.is_a?(String) && device_types =~ /^\[.*\]$/
      unless device_types.sort == multi_chosen_field_values('offer_device_types').sort
        chosen_select_multiple(device_types, from: 'offer[device_types][]')
      end
    end

    # Update the targeted os versions using the provided array
    # @param [Array(Symbol,String)] target_os_versions
    def update_target_os_versions(target_os_versions)
      if target_os_versions
        clear_os_targeting
        target_os_versions.each do |os_version|
          find(:css, '.target_os_versions').find(:css, "'input[val='#{os_version}']").set(true)
        end
      else
        clear_os_targeting
      end
    end

    # Update the connection types using the provided array
    # @param [Array(Symbol,String)] connection_type
    def update_connection_type(connection_type)
      if connection_type
        clear_connection_type
        connection_type = [connection_type] unless connection_type.is_a? Array
        connection_type.each do |type|
          find(:css, "#offer_connection_type_[value='#{type}']").set(true)
        end
      else
        clear_connection_type
      end
    end

    # Update the moments chosen field using the provided array
    # @param [Array(Symbol,String)] moments
    def update_moments(moments)
      unless moments.sort == multi_chosen_field_values('offer_moments').sort
        chosen_select_multiple(moments, from: 'offer[moments][]')
      end
    end

    # Deselect all targeting OS versions
    def clear_os_targeting
      find(:css, 'target_os_versions input').each do |field|
        field.set(false)
      end
    end

    # Deselect all connection types
    def clear_connection_type
      find(:css, '#offer_connection_type_').each { |field| field.set(false) }
    end

  end
end
