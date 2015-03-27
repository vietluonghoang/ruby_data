module TestChamber
  module Models
    class VideoOffer < ActiveRecord::Base
      self.primary_key = :id

      json_set_field :exclusion_prerequisite_offer_ids
    end
  end
end
