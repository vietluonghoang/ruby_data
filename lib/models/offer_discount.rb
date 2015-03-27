module TestChamber
  module Models
    class OfferDiscount < ActiveRecord::Base
      belongs_to :partner
    end
  end
end
