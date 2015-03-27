module TestChamber::Creator
  class Video
    module UiV1
      def create!
        if tracking_offer
          raise "Right now we can only create tracking offers when 'create_with' is set to Api. If you need this automated in the UI please let the Tools team know."
        end
        TestChamber::Partner.act_as!(partner_id)
        self.name ||= "#{title} name"
        self.details ||= "#{title} details"
        self.objective_id ||= '201'

        page.click_link('Create Video Offer')
        fill_in 'video_offer_name', :with => name
        fill_in 'video_offer_primary_offer_attributes_title', :with => title
        fill_in 'video_offer_primary_offer_attributes_details', :with => details
        # required to select but the value is only used by datascience right now
        # so we can just pick one.
        find('#video_offer_primary_offer_attributes_offer_objective_id').select(objective_id)
        find(:css, "#video_offer_primary_offer_attributes_offerwall").set(allow_on_offerwall)
        attach_file('video_offer_input_video_file', video_path)
        attach_file('icon', icon_path)

        # There is a two step sumbission process, thus two clicks to the same button.
        click_button 'video_offer_submit'
        click_button 'video_offer_submit'
        id_from_page

        enable
      end
    end
  end
end
