# Creating survey offer objects as dummy objects that don't inherit from offer/
# This is becasue we should no longer be allowed to create survey offers

module TestChamber
  class Offer
    class Survey < Offer

    end
  end
end
