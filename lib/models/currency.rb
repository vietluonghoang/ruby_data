module TestChamber
  module Models
    class Currency < ActiveRecord::Base
      self.primary_key = :id

      json_set_field :promoted_offers

      def rewarded?
        conversion_rate > 0
      end
    end
  end
end
