##
# Mixin module to extend offerwall with mobile methods and DRY ios and android code up.
# Any methods called exclusively after changing to a webview context can live in this module, plus any carefully
# factored methods that can be used on ios and android with different selectors.
##

module TestChamber
  class Offerwall
    module MobileMethods
      def self.extend_object(base)
        case Capybara.current_driver
        when :ios
          include TestChamber::Offerwall::IOSConstants
        when :android
          include TestChamber::Offerwall::AndroidConstants
        end
        super
      end

      # Navigate to offerwall.
      # This switches from the native automation context into a webview context
      # which behaves the same as a browser. Everything until the `set_context`
      # call needs to use native selectors. `appium_capybara` should handle this
      # difference seamlessly.
      # @return [void]
      # @see (Offerwall#visit_offerwall)
      def visit_offerwall
        # Set native context in case this isn't our first pass at the offerwall.
        page.driver.appium_driver.set_context('NATIVE_APP')

        # Sleep because EasyApp has to complete a connect call before we can proceed.
        # There is nothing we can poll on to automate this wait.
        sleep 5

        # Alert popup is ios only but this is fine to try on android too because this selector will return nil
        page.accept_alert if page.first(:class, 'UIAAlert')

        offerwall_button = Util.wait_for { page.first(*OFFERWALL_LOCATOR) }
        offerwall_button.click
        spinner = page.first(*SPINNER_LOCATOR)
        Util.wait_for(120, 1) { !spinner.visible? }

        @context = page.driver.appium_driver.available_contexts.last
        page.driver.appium_driver.set_context(@context)

        if no_more_offers?
          raise "No offers on offerwall"
        end

        offers
        set_device_properties
      end

      # Click on an offer.
      # @param id [String] Id of the offer to click.
      # @return [TestChamber::Offer] A TestChamber::Offer object representing the offer that was clicked.
      def click_offer(id)
        url = offer_map[id][:click_url]
        els = page.all(:css, 'li.offer-item a')
        els.find { |o| o["href"] == url.to_s }.click
        offer = offers.find { |o| o.id == id }
        @offer_map = nil
        offer
      end

      # Check whether the offerwall is currently displayed. Will return true even if "Loading..." spinner is displayed.
      # IMPORTANT: This will crash Chromedriver if you use it while the offerwall is loading on Android.
      # @return [Bool] Whether the offerwall is displayed.
      def displayed?
        displayed = false
        webview_context = page.driver.appium_driver.available_contexts.last
        page.driver.appium_driver.within_context(webview_context) do
          if webview_context.start_with? "WEBVIEW"
            offers = page.first(:css, "#offers")
            displayed = !offers.nil? && offers.visible?
          end
        end
        displayed
      end

      # Check if the offerwall is fully loaded. Will return false if the "Loading..." spinner is still displayed.
      # Pulls the 'SPINNER_LOCATOR' array out of the appropriate module.
      # @return [Bool] Whether the offerwall is loaded.
      def loaded?
        loaded = false
        if displayed?
          page.driver.appium_driver.within_context("NATIVE_APP") do
            spinner = page.first(*SPINNER_LOCATOR)
            loaded = !spinner.nil? && !spinner.visible?
          end
        end
        loaded
      end

      # Close the offerwall by clicking the 'X' button. Will return appium to the 'NATIVE_APP' context.
      # @return [void]
      def close_offerwall
        page.driver.appium_driver.set_context('NATIVE_APP')
        page.find(*CLOSE_BUTTON_LOCATOR).click
        raise "Offerwall failed to close" unless Util.wait_for(5, 1) { !displayed? }
        @offer_map = nil
      end

      # Hack to set device ID correctly for clicks.
      # This is incompatible with passing device ID to OptSOA because the offerwall
      # is already loaded at this point.
      # Set the advertising id, publisher user id, and udid from offerwall params.
      def set_device_properties
        TestChamber.current_device.advertising_id = @params[:advertising_id]
        TestChamber.current_device.publisher_user_id = @params[:publisher_user_id]
        TestChamber.current_device.udid = @params[:udid]
      end
    end
  end
end
