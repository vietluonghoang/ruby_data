module TestChamber::Creator
  class Generic
    module UiV1

      def create!
        TestChamber::Partner.act_as!(partner_id)
        page.click_link('Create Generic Offer')
        fill_in 'generic_offer_name', :with => "#{title} name"
        fill_in 'generic_offer_primary_offer_attributes_title', :with => "#{title}"
        fill_in 'generic_offer_primary_offer_attributes_details', :with => "#{title} details"
        fill_in 'generic_offer_summary', :with => "#{summary}"
        find(:css, "#generic_offer_primary_offer_attributes_offerwall[value='1']").set(true)
        # CPA is a somewhat arbitrary choice. Just need to pick one.
        select("CPA",:from => "generic_offer_category")

        if instructions
          fill_in 'generic_offer_instructions', :with => "#{instructions}"
        end

        ## Offer objective field is required to enable an offer.  This seems to be related to the 'purpose' of
        ## the offer for data-science.  More documentation on the field can be found here -
        ## https://docs.google.com/a/tapjoy.com/document/d/1uzmvp7B1YANz27vJRXRtb8uU33wTlavsxU77QPihbhI/edit
        ##
        ## TODO: This should be a parameter/instance var. but requires a bit more understanding
        ## at least at the time of implementation
        select '401', from: 'generic_offer[primary_offer_attributes][offer_objective_id]'

        fill_in 'generic_offer_url', :with => "#{offer_url}"
        attach_file('icon', icon_path)

        click_button 'generic_offer_submit'

        id_from_page

        enable
      end

      def visit_create_page
        TestChamber::Partner.act_as!(partner_id)
        page.click_link('Create Generic Offer')
      end
    end
  end
end
