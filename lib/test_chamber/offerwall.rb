module TestChamber
  class Offerwall
    include Capybara::DSL
    include TestChamber::Rest

    extend Gem::Deprecate

    # Load an offerwall in the given app.
    # Automatically includes the module for Capybara.current_driver.
    # @param app [String] Id of the App that's opening the offerwall.
    def initialize(app: app, **options)
      case Capybara.current_driver
      when :selenium
        extend TestChamber::Offerwall::Web
      else
        extend TestChamber::Offerwall::MobileMethods
      end
      @app = app
      visit_offerwall
    end

    # Navigates to offerwall via url or SDK button.
    # Implemented by offerwall modules.
    # @return [void]
    def visit_offerwall
      raise NotImplementedError
    end

    def loaded?
      raise NotImplementedError
    end

    def displayed?
      raise NotImplementedError
    end

    def close_offerwall
      raise NotImplementedError
    end

    # The array of 'Offer' object ids for each offer on the offerwall.
    # @return [Array] The array of Offer ids for the offerwall.
    def offer_ids
      offers.map(&:id)
    end

    # The array of `Offer` objects for each offer on the offerwall.
    # @return [Array] The array of Offers for the offerwall.
    def offers
      @offers ||= offer_map.values.map { |v| v[:offer] }
    end

    # Whether there are visible offers on the offerwall.
    # @return [Boolean]
    def no_more_offers?
      message = first('#message')
      message && message.text == "Come back later for more offers."
    end

    # Click the offer in the offerwall with the given id.
    # Implemented by Offerwall modules.
    # @abstract
    # @param id [String] The id of the offer to click.
    # @return [Offer] The offer object displayed after click.
    def click_offer(id)
      # @todo: This should raise if the offer is not on the wall.
      raise NotImplementedError
    end

    # Click the offer in the offerwall with the given index.
    # Offers are indexed left to right (if applicable), top to bottom.
    # Implemented by Offerwall modules.
    # @abstract
    # @param idx [Integer] The index of the offer to click, corresponding to the
    #   location of the offer on the offerwall. This is zero indexed.
    # @return [Offer] The offer object displayed after click.
    def click_offer_by_index(idx)
      # @todo: This should raise if the offer is not on the wall.
      raise NotImplementedError
    end

    ##
    # Converting offers from the offerwall directly has been deprecated and will
    # be removed from a future release of test chamber. Use Offer#convert!
    ##

    # Convert the offer in the offerwall with the given id.
    # Clicks and converts the offer. Implemented by Offerwall modules.
    # @abstract
    # @param id [String] The id of the offer to convert.
    # @return Conversion The conversion object for the offer.
    # @deprecated Please use Offer#convert! instead.
    def convert_offer(id)
      raise NotImplementedError
    end
    deprecate :convert_offer, :click_offer, 2015, 03

    # Convert the offer in the offerwall with the given index.
    # Offers are indexed left to right (if applicable), top to bottom. Clicks
    # and converts an offer. Implemented by Offerwall modules.
    # @abstract
    # @param idx [Integer] The index of the offer to convert, corresponding to
    #   the location of the offer on the offerwall. This is zero indexed.
    # @return Conversion The conversion object for the offer.
    # @deprecated Please use Offer#convert instead.
    def convert_offer_by_index(idx)
      raise NotImplementedError
    end
    deprecate :convert_offer_by_index, :click_offer_by_index, 2015, 03

    private

    # Retrieve the offer id from the encrypted url of the offer.
    # @param url [String] The url of the offer scraped from the offerwall.
    # @return Id The id of the offer from decrypting the url.
    def offer_id_from_url(url)
      encrypted_params = CGI::parse(url.query)
      @params = ObjectEncryptor.decrypt(encrypted_params['data'].first)

      if url.path.include?('/videos/')
        url.path.split('/')[2]
      elsif url.path.include?('/click/generic') ||
            url.path.include?('/click/mraid') ||
            url.path.include?('/click/app') ||
            url.path.include?('/click/survey') ||
            url.path.include?('/click/action')
        # entity_id and offer_id are the same thing, is this always the case?
        @params[:entity_id]
      else
        nil
      end
    end

    # Generates or returns a map of offer ids to offers and click_urls.
    # @return Map A map of offer ids to offers and click_urls.
    def offer_map
      return @offer_map unless @offer_map.nil?

      if no_more_offers?
        raise "The offerwall didn't have any more offers to render. We got " \
        "the 'Come back later for more offers.' message. You may have to " \
        "create more offers to run your test."
      end

      Util.wait_for(60,1) do
        page.has_css?('#offers')
      end

      @offer_map = {}

      # Offers under marquee-offers would never overlap with the offers from
      # offer-item. This is ensured via offer filtering on TJS. Hence, we need
      # to parse for them seperately to be able to make assertions about
      # marquee/premium offers.
      parse_offers('#marquee-offers')
      parse_offers('#offers')

      @offer_map
    end

    # Parse the offerwall and call the Offer Factory for each offer found.
    # Stores the resulting click urls and offers in the offer map.
    # @param locator [String] the locator to use to find the offers. Generally
    #   either '#marquee-offers' or '#offers'.
    # @return [void]
    def parse_offers(locator)
      page.all(:css, locator).each do |offer_sections|
        offer_sections.all(:css, 'a').each do |offer_item|
          raw_url = offer_item['href']
          link = URI.parse(raw_url)
          offer_id = offer_id_from_url(link)
          offer = OfferFactory.make_offer(offer_id)
          if offer_id
            @offer_map[offer_id] = { click_url: link, offer: offer }
          else
            raise "Error parsing the offer URL from the offerwall. Expected " \
              "Offer ID, but got #{offer_id}. The URL parsed was #{raw_url}"
          end
        end
      end
    end
  end
end
