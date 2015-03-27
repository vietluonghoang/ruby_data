module TestChamber
  class Offerwall
    module AndroidConstants
      # These are the Locators we use for Android finder methods. Native only.
      # Are always of the format [strategy, locator]. These are available as constants on the Offerwall class when this
      # module is mixed-into the Offerwall.
      OFFERWALL_LOCATOR    = [:name, 'Offers']
      SPINNER_LOCATOR      = [:class, 'android.widget.ProgressBar']
      CLOSE_BUTTON_LOCATOR = [:class, 'android.widget.ImageButton']
    end
  end
end
