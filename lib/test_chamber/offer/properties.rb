module TestChamber
  class OfferProperties < Properties
    # @!group Settings

    setting :cid, -> { TestChamber::Random.cid }

    setting :form_id, -> { TestChamber::Random.digits }

    setting :start_date, -> { Time.now }

    setting :end_date, -> { 2.weeks.from_now }

    setting :admin_only, NoDefaultValue

    setting :ppi_instructions, NoDefaultValue

    # @!endgroup
    # @!group Properties

    property :partner_id, -> { TestChamber.default_partner_id }

    property :title, -> (s) { "test-chamber #{s.class.name.demodulize} offer #{Util.name_datestamp}" }

    property :details, -> (s) { "#{s.title} details" }

    # TODO
    # default offer has device type of ipad. Shouldn't that be provided by the device?
    # it appears to be used for targetting but if our default device is android how does this work?

    property :device_types, %w{ipad iphone itouch android windows}.to_set

    property :store_name, ''

    property :age_rating

    property :overall_budgeted_spend, 0

    property :overall_budget, 0

    property :daily_budgeted_spend, 0

    property :some_or_all_ios_versions, 'all'

    property :some_or_all_android_versions, 'all'

    property :ad_type, 'engagement'

    property :rewarded, true

    property :placement, 'marketplace'

    property :bid, 1

    property :geotarget_by, 'all'

    property :daily_budgeted_spend_toggle, 'unlimited'

    property :overall_budgeted_spend_toggle, 'unlimited'

    property :overall_budget_toggle, 'unlimited'

    property :platform, %w{ios android}.to_set

    property :countries, %w{}.to_set

    property :regions, %w{}.to_set

    property :cities, %w{}.to_set

    property :dma_codes, %w{}.to_set

    property :objective_id, 201

    property :featured, false

    property :summary, 'Summary'

    property :instructions, nil

    property :short_description, 'Short description'

    property :name, 'name'

    property :video_url, 'http://videourl.com'

    property :marquee_preview_image_path, './assets/300x250_image.png'

    property :icon_path, './assets/generictest.png'

    property :background_path, './assets/300x250_image.png'

    property :bannercreative_path, './assets/300x250_image.png'

    property :tapjoy_enabled, true

    property :user_enabled, true

    property :self_promote_only, false

    property :allow_negative_balance, true

    property :allow_on_offerwall, true

    property :require_admin_device, false


    property :id, NoDefaultValue

    property :monetary_min_bid_override, NoDefaultValue

    property :moment_name, NoDefaultValue

    property :item_id, NoDefaultValue

    property :publisher_app_id, NoDefaultValue

    property :item_type, NoDefaultValue

    property :multi_complete, NoDefaultValue

    property :objective, NoDefaultValue

    property :target_os_versions, NoDefaultValue

    property :connection_type, NoDefaultValue

    property :premium, NoDefaultValue

    property :direct_pay, NoDefaultValue

    property :name_suffix, NoDefaultValue

    property :moments, NoDefaultValue

    property :featured_ad_action, NoDefaultValue

    property :featured_ad_content, NoDefaultValue

    property :monetary_bid, NoDefaultValue

    property :app_id, NoDefaultValue

    property :tpat_enabled, NoDefaultValue

    property :click_url, NoDefaultValue
  end
end
