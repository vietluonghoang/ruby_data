module TestChamber
  class Offerwall
    module IOSConstants
      # These are the Locators we use for iOS finder methods. Native only.
      # Are always of the format [strategy, locator]. These are available as constants on the Offerwall class when this
      # module is mixed-into the Offerwall.
      OFFERWALL_LOCATOR    = [:name, 'Show Offerwall']
      SPINNER_LOCATOR      = [:name, "Loading..."]
      CLOSE_BUTTON_LOCATOR = [:name, "TJCclose button"]
    end
  end
end
