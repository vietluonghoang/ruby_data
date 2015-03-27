module TestChamber::Creator
  class Mraid
    module UiV1
      def create!
        TestChamber::Partner.act_as!(partner_id)
        page.click_link('Create MRAID Offer')

        fill_in 'mraid_offer_name', :with => "#{title} name"
        fill_in 'mraid_offer_primary_offer_attributes_title',
                :with => title
        fill_in 'mraid_offer_primary_offer_attributes_details',
                :with => "#{title} details"
        fill_in 'mraid_offer_mraid_content_attributes_content',
                :with => mraid_phone_txt
        attach_file('icon', icon_path)

        ## Offer objective field is required to enable an offer.  This seems to be related to the 'purpose' of
        ## the offer for data-science.  More documentation on the field can be found here -
        ## https://docs.google.com/a/tapjoy.com/document/d/1uzmvp7B1YANz27vJRXRtb8uU33wTlavsxU77QPihbhI/edit
        ##
        ## TODO: This should be a parameter/instance var. but requires a bit more understanding
        ## at least at the time of implementation
        select '501', from: 'mraid_offer[primary_offer_attributes][offer_objective_id]'

        click_button 'mraid_offer_submit'
        id_from_page

        enable
      end
    end
  end
end
