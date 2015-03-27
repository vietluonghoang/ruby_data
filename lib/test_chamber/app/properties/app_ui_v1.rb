module TestChamber
  class AppProperties::UiV1 < AppProperties
    # @!group Properties

    property! :name, -> { "test-chamber-app_#{Util.name_datestamp}" }

    property :version, -> { (1..[3,4].sample).map { rand(10) }.join('.') }

    property! :platform, 'android'

    property! :create_with, :ui_v1

    property! :edit_with, :ui_v1

    property :apps_network_id, nil

    property :rev_share_override, nil

    property :create_non_rewarded_currency, false

    property :state, 'live'

    property :bridge_version, '1.0.3'
  end
end
