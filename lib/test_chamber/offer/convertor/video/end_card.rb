##
# Abstraction of the Video Offer end card.
#
# The end card is displayed within a constructed webview that is not the same webview as the offerwall, therefore all
# selectors in this class and inline classes must be wrapped with `within_context` to ensure that we are interacting
# with the correct scope.
#
# The page elements like the Replay Button are abstracted into inline classes for your amusement.
##

module TestChamber::Convertor
  module Video
    class EndCard

      include Capybara::DSL

      class ReplayButton
        def initialize(button_el)
          @button = button_el
        end

        # @return [Hash] A hash with :x and :y keys.
        def location
          @location ||= @button.native.location.to_h
        end

        # @return [Hash] A hash with :width and :height keys.
        def dimensions
          @dimensions ||= @button.native.size.to_h
        end

        def replay!
          @button.first(:css, '.cover .arrow').click
        end

        def visible?
          @button.visible?
        end

        def arrow_visible?
          @button.first(:css, '.cover .arrow').visible?
        end

        # @return [String, nil] Returns the url or base64 encoded image if present. If not present, returns nil.
        def background_image
          return @bg unless @bg.nil?
          bg = @button.first(:css, '.cover').native.css_value('background_image')
          # Selenium returns "none" when the image isn't present but we want a falsey.
          @bg = (bg != "none" ? bg : nil)
        end
      end

      class TrackingCard
        def initialize(card_el)
          @card = card_el
        end

        def dimensions
          @dimensions ||= @card.native.size.to_h
        end

        def location
          @location ||= @card.native.location.to_h
        end

        def button
          @button ||= @card.first(:id, 'cta')
        end

        def button_location
          @button_location ||= button.native.location.to_h
        end

        def button_text
          @button_text ||= button.text
        end

        # @return [String, nil]
        def icon
          return @icon unless @icon.nil?
          icon = icon_element['src']
          @icon = (icon != "" ? icon : nil)
        end

        def icon_location
          @icon_location ||= icon_element.native.location.to_h
        end

        def icon_dimensions
          @icon_dimensions ||= icon_element.native.size.to_h
        end

        def text
          @text ||= text_element.text
        end

        def text_location
          @text_location ||= text_element.native.location.to_h
        end

        private

        def icon_element
          @icon_el ||= @card.first(:id, 'completed-offer-icon')
        end

        def text_element
          @text_el ||= @card.first(:id, 'completed-offer-title')
        end
      end

      # Create a new EndCard instance
      # @param offer [TestChamber::Offer] An instance of TestChamber::Offer or one of it's subclasses.
      def initialize
        # Get the webview that the end card is displayed in and store it for use in the `within_context` blocks.
        get_webview_context
      end

      # @return [String, nil] The url of the background_image, or nil if not present.
      def background_image
        return @bg unless @bg.nil?
        bg = page.first(:id, 'bg-image')['src']
        @bg = (bg != "" ? bg : nil)
      end

      def displayed?
        content = page.first(:id, 'content-wrapper')
        content && content.visible?
      end

      def replay!
        replay_button.replay!
      end

      def click!
        tracking_card.button.click
      end

      def replay_button
        @replay_button ||= ReplayButton.new(page.first(:css, '.replay'))
      end

      def reward_text
        @reward_text ||= page.first(:css, '.reward-text').text
      end

      def tracking_card
        @tracking_card ||= TrackingCard.new(page.first(:id, 'info'))
      end

      private

      # Set the appium context programmatically by searching for the 'content-wrapper' div among the possible webviews.
      # This changes the appium state to be using the webview for the end card which is different than the offerwall.
      # Called during TC::Offer::Video::Endcard creation.
      def get_webview_context
        # Start at last context
        page.driver.appium_driver.set_context(page.driver.appium_driver.available_contexts.last)

        def try_contexts
          # Get context and raise if NATIVE_APP because end card can never be in NATIVE_APP
          context = page.driver.appium_driver.current_context
          raise "Couldn't find end card" if context == 'NATIVE_APP'

          # Check if the context we're on now contains the content-wrapper div, because that's the end card.
          return context if displayed?

          # Go back one context and try again.
          ctxs = page.driver.appium_driver.available_contexts
          page.driver.appium_driver.set_context(ctxs[ctxs.index(context) - 1])
          try_contexts
        end

        try_contexts
      end
    end
  end
end
