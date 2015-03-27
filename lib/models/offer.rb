module TestChamber
  module Models
    class Offer < ActiveRecord::Base
      self.primary_key = :id

      json_set_field :device_types, :screen_layout_sizes, :countries, :dma_codes, :regions,
        :approved_sources, :carriers, :cities, :exclusion_prerequisite_offer_ids,
        :language_filters, :device_model_filters

      belongs_to :app, :foreign_key => "item_id"
      has_many :offer_properties

      def enabled?
        tapjoy_enabled && user_enabled
      end

      def compound_template_url
        prop = offer_properties.find do |op|
          op.name == 'compound.template_url'
        end
        prop.nil? || prop.value.empty? ? nil : prop.value
      end
    end
  end
end
