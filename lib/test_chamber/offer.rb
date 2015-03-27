module TestChamber
  # Abstract base class for all Offer types
  class Offer
    include TestChamber::OfferParams
    include TestChamber::Creator::InstanceMethods

    include UniqueName
    include Capybara::DSL
    # Must be after Capybara::DSL
    include TestChamber::Properties::InstanceMethods
    include TestChamber::ConfirmationDialog
    include TestChamber::Login
    include TestChamber::Rest
    include ActiveModel::Model
    include ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Serialization

    validates_presence_of :id, :partner_id, :title, :bid, :device_types, :objective_id

    # used for tpat enabled offers
    attr_accessor :campaign, :tracking_url

    extend Gem::Deprecate

    CLICK_MACROS = {
      generic_source:            "TAPJOY_GENERIC_SOURCE",
      external_uid:              "TAPJOY_EXTERNAL_UID",
      # This macro is not included in FakeHasOffers, comment it out for now
      #device_click_ip:           "TAPJOY_HASHED_KEY",
      hashed_mac:                "TAPJOY_HASHED_MAC",
      advertising_id:            "TAPJOY_ADVERTISING_ID",
      raw_ad_id:                 "TAPJOY_RAW_ADVERTISING_ID",
      hashed_ad_id:              "TAPJOY_HASHED_ADVERTISING_ID",
     #hashed_raw_advertising_id: "TAPJOY_HASHED_RAW_ADVERTISING_ID",
      android_id:                "TAPJOY_ANDROID_ID",
      raw_android_id:            "TAPJOY_RAW_ANDROID_ID",
      hashed_android_id:         "TAPJOY_HASHED_ANDROID_ID",
      hashed_raw_android_id:     "TAPJOY_HASHED_RAW_ANDROID_ID",
      click_key:                 "TAPJOY_GENERIC",
    }

    # Create a new offer with the dashboard, or populate info from an existing id
    # @param attributes [Properties, Hash] Properties for the offer, if a
    #   hash is provided a new Properties will be instantiated using the
    #   hash. All properties are available as accessors on the offer through
    #   method_missing
    def initialize(attributes = {})
      self.attributes = wrap_attributes(attributes, :create_with)
      include_creation_module(self.creator_module)

      # if id was passed in through the options then it will already be set by store_options
      if id
        # update instance variables with data from model
        # tracking offers come back from TJS without a title or details, which are
        # required to enable the offer...
        record.update_attributes(title: self.title, details: self.details)
        merge_record
      else
        create!
        # Call this to set the id value in the offer properties (if id is nil),
        # the offer_params module and if its not set when that happens weirdness
        # ensues.
        id_from_page if id.nil?
      end

      validate_offer = self.attributes.validate
      if validate_offer && self.invalid?
        raise "Invalid Offer, errors: \n #{collect_errors}"
      end

      if tpat_enabled
        enable_third_party_tracking!
        set_destination_url!(@tracking_url)
      end
    end

    def compound_template_url
      self.record(reload: true).compound_template_url
    end

    def record(reload: false)
      if @record.nil?
        reload = false # don't reload if we don't have the record yet
      end
      @record ||= TestChamber::Models::Offer.find(id)
      @record.reload if reload
      @record
    end
    def merge_record
      self.attributes.merge!(record(reload: true).attributes)
    end

    # All active model validation errors as a single string
    # @return [String] All active model validation errors joined by "\n"
    def collect_errors
      self.errors.full_messages.join("\n")
    end

    # Edit an offer providing a hash of attributes or a Properties object.  Method will update only properties found
    # in the parameter.  Parameter can optionally include edit_with action or an editor_module to use.
    # @param properties [Hash, Properties] the properties to update on the offer, supports a hash like object or a
    #   TestChamber::Properties object.  When a hash is provided a new a Properties object will be created, for properties
    #   type resolution see TestChamber::Properties.class_for
    # @option properties [optional, Symbol] :edit_with (:api) The action to use when editing the offer (:api, :ui_v1, :ui_v2)
    # @option properties [optional, Module] :editor_module The module to use when editing the offer, must implement #edit!
    #   ( see TestChamber::Offer#edit! )
    # @option properties [optional, Boolean] :validate (true) Validate the offer and raise any errors
    def edit(properties = {})
      properties = wrap_attributes(properties, :edit_with, ignore_defaults: true)
      if properties.validate && self.invalid?
        raise "Invalid Offer, errors: \n #{collect_errors}"
      end

      self.attributes.merge!(properties)
      include_editor_module(properties.editor_module)

      # edit! must be implemented by the included editor module
      self.edit!(properties)
    end

    # Returns the click_action associated with each offer type.
    #   This method was added to mirror the functionality of offer model objects in TJS
    #   In TJS this method returns a mapping of the offer's item_type to click_action
    #   Rather than relying on a db lookup for this method, each subclass will define the mapping
    #
    # This method will most likely be usesful in spec verifications such as the tracking_service/clicks_spec
    #
    # @return [String] the click_action
    def click_action
      raise NotImplementedError "Subclasses must implement this method"
    end

    # Enable an offer by setting 'tapjoy_enabled', and 'user_enabled' to true and populating fields necessary to enable
    # an offer.  Method calls TestChamber::Offer#edit followed by querying the model and asserting it is enabled.
    # @param [Hash] options define and/or override properties used to enable the offer.  These properties are passed to
    #   the offer's edit method (see TestChamber::Offer#edit)
    # @option [optional, Boolean] :self_promote_only (false) Mark offer as 'self_promote'
    # @option [optional, Boolean] :admin_only (false) Mark offer as an 'admin_only' offer
    # @option [optional, Boolean] :featured (false) Mark offer as a featured offer
    def enable(options = {})
      # Why is this here? Why are the defaults not whats set on this object?
      #options = options.reverse_merge({
        #self_promote_only: false,
        #admin_only:        false,
        #featured:          false
      #})
      properties = wrap_attributes(options, :edit_with, ignore_defaults: true)

      properties.tapjoy_enabled = true
      properties.user_enabled   = true

      properties.self_promote_only = self.self_promote_only unless options.key?(:self_promote_only)
      properties.admin_only        = self.admin_only unless options.key?(:admin_only)
      properties.featured          = self.featured unless options.key?(:featured)

      properties.title              ||= self.attributes.fetch_with_default(:title)
      properties.details            ||= self.attributes.fetch_with_default(:details)
      properties.require_admin_device = !!properties.admin_only
      properties.ppi_instructions     = !!self.instructions

      properties.objective_id           = self.objective_id
      properties.bid                    = self.bid
      properties.allow_negative_balance = self.allow_negative_balance
      properties.device_types           = self.device_types
      properties.moments                = self.moments

      properties.compound_template_url = self.compound_template_url if self.compound_template_url

      if properties.featured
        properties.featured_ad_action  = 'featured_ad_title_demo'
        properties.featured_ad_content = 'featured_ad_content_demo'
      end

      self.edit(properties)

      unless record(reload: true).enabled?
        raise "The offer in the db was not enabled even after we enabled it in the UI. Offer ID: #{id}"
      end
    end

    def complete?(device = TestChamber.current_device)
      return false if multi_complete
      device_model = TestChamber::Models::Device.find(device.normalized_id)
      device_model.attribute('apps').include?(item_id || self.record.item_id)
    end

    # Returns the most recent click for this offer, if one exists, otherwise
    # raises. Contains some logic that checks the most recent mistakes with a
    # click and raises specific error messages.
    def click(params={})
      # usually getting clicks from riak takes less than 30 seconds.
      # However PPI Offers can take up to 1 minute.
      actual_click_key = params[:click_key] || click_key

      begin
        Util.wait_for(60, TestChamber.default_wait_for_interval, {click_key: actual_click_key}) do
          last_click = TestChamber::Models::Click.find(actual_click_key)

          if last_click.nil?
            rev_click = TestChamber::Models::Click.find(reverse_normalization(actual_click_key))
            msg = "We were looking for a click with the key #{actual_click_key} which we didn't find. However we did" \
                  " find the key #{reverse_normalization(actual_click_key)} which might mean that the expected"\
                  " normalization of device identifiers is incorrect:\nThe click found was: \n#{rev_click.inspect}"
            raise WaitForAbort, msg if rev_click
          end

          last_click
        end
    rescue => e
        e.message << "\n\nCurrent device: #{TestChamber.current_device.inspect}"

        other_clicks = TestChamber.riak['clicks'].keys.find_all do |k|
          k.include?(id)
        end
        # Helpful debugging information if clicks are being created with unexpected
        # device information
        e.message << "\n\nAll other clicks found on the test server with the offer id #{id} are:\n\n#{other_clicks}" if other_clicks
        raise e
      end
    end


    # Extends the offer class with the module corresponding to the current
    # Capybara driver, then calls do_conversion! from that module.
    #
    # This method has to collect *args to support conversion because we don't
    # currently have any way to tell what app we're converting from except passing
    # the app as a param. If clicking returned the click and we passed the click to
    # the conversion, it would solve the problem since we could extract the app
    # from the click. For conversion in appium, the publisher_app is not a needed
    # param so we have to keep the method signature abstract with a splat.
    def convert!(*args)
      params = args.last.is_a?(Hash) ? args.last : {} # :[] OM NOM NOM
      base_name = compound_template_url ? 'Compound' : self.class.name.demodulize
      driver = case Capybara.current_driver
               when :selenium then 'Web'
               when :ios      then 'IOS'
               when :android  then 'Android'
               end

      convertor = "TestChamber::Convertor::#{base_name}::#{driver}"

      begin
        conversion_module = convertor.constantize
      rescue NameError => e
        # For the web, we are ok with a generic fallback behavior. Don't raise
        # if it's not overriden.
        unless Capybara.current_driver == :selenium
          e.message << "\nCouldn't find the conversion module '#{convertor}'."
          raise e
        end
        conversion_module = TestChamber::Convertor::Web
      end

      extend conversion_module

      # Offers with TPT enabled use a third party SDK. We simulate the ping
      # to the third party (instead of a regular connect) by pinging the fake
      # third party service set up on the TIAB.
      #
      # Mixing in this behavior overrides do_conversion.
      if tpat_enabled
        extend TestChamber::Convertor::TPAT
      end

      last_click = click(params)
      # Get the converting app from the last click.
      converting_app = App.new(id: last_click.attribute('publisher_app_id'))

      do_conversion!(converting_app, params)
      conversion(converting_app, params)
    end

    def conversion(publisher_app, params={})
      # TODO get initial point purchase balance
      conversion = nil
      last_click = click(params)
      reward_key = last_click.attribute('reward_key')

      Util.wait_for(120,
                    TestChamber.default_wait_for_interval,
                    {:click_data => last_click}) do
        # we are trying to read the conversions from database using reward key
        conversion = TestChamber::Models::Conversion.find(reward_key)
      end
      # TODO verify point purchase balance after conversion
      conversion
    end

    # Complete an offer by clicking it's end card, or performing an additional action.
    # Implemented by convertor Mixin.
    def complete!
      raise NotImplementedError
    end

    def close_offer!
      raise NotImplementedError
    end

    # click! and click_with_rest! are provided here for clicks outside the offerwall.
    # Please think very hard if you're using this, whether it's worth it.
    def click_with_rest!(publisher_app)
      rest_request(:get, get_click_url(publisher_app), format: :html)
      click
    end

    def click!(publisher_app)
      visit get_click_url(publisher_app)
      click
    end

    # Implemented by web conversion module only
    def convert_with_rest!(*args)
      raise NotImplementedError, "Convert with rest not supported on platform."
    end

    # Implemented by conversion modules
    def do_conversion!(*args)
      raise NotImplementedError
    end

    ##
    # These click and conversion methods are deprecated. They have been replaced
    # with the Convertor modules and should not be used. They will be removed in
    # a future release:
    #
    # Offer#complete_click
    # Offer#initiate_conversion
    # Offer#complete_conversion
    # Offer#convert
    ##

    # Visit `display_offer_url` and click on the ad there
    # @deprecated Please use Offerwall#click! instead.
    def complete_click(publisher_app)
      click_with_rest! publisher_app
    end
    deprecate :complete_click, :none, 2015, 03

    # Can be overridden by subclasses that initiate conversions differently.
    # The default is to go to /ad_unit/convert which may not be appropriate.
    # For example PPIOffers need to initiate a connect call to simulate an app opening
    # @deprecated Please use Offer#convert! instead. If you absolutely must
    # use a rest client call for convert, use Offer#convert_with_rest!
    def initiate_conversion(publisher_app, params={})
      convert_with_rest!(publisher_app, params=params)
    end
    deprecate :initiate_conversion, :convert_with_rest!, 2015, 03

    # Complete the offer and then verify various parts of the conversion completing
    #
    # Wait for the click to hit Riak and then wait for the conversion to hit MySQL
    # Verify point purchase balances before and after conversion
    # @deprecated Please use Offer#convert! instead.
    def complete_conversion(publisher_app, params={})
      # we determine publisher app from the click data, so drop that param.
      convert!(params=params)
    end
    deprecate :complete_conversion, :convert!, 2015, 03

    # @deprecated Please use Offer#convert! instead.
    def convert(publisher_app)
      complete_click(publisher_app)
      return complete_conversion(publisher_app)
    end
    deprecate :convert, :convert!, 2015, 03

    # OS targeting properties for the offer
    # @param options [Hash] Hash of the form: `{ (Android|iOS): ['X.x', ...], ... }`
    def target_os(options = {})
      visit edit_url
      options.each do |os, versions|
        versions.each do |version|
          find(:css, "#offer_target_os_versions_[value='#{os}_#{version}']").click
        end
      end
      click_button 'Save Changes'
    end

    # Device targeting settings for the offer
    # @param devices [Array] device models to target. Valid options are: android, iphone, ipad, itouch, windows
    def target_devices(*devices)
      visit edit_url
      # reset the currently selected devices
      page.evaluate_script("$('#offer_device_types option').each(function() { $(this).attr('selected', null); })")
      devices.each do |device|
        # re-select the given devices
        page.evaluate_script("$('#offer_device_types option[value=\"#{device}\"]').attr('selected', 'selected')")
      end
      click_button 'Save Changes'
    end

    def change_app_blacklist(apps)
      visit edit_url
      find('#publisher_app_filter_blacklist').set(true)
      fill_in('offer[publisher_app_blacklist]', :with => apps.join(';'))
      click_button 'Save Changes'
    end

    # Open the webpage for just this offer in the browser. This allows us to click on it to start trying
    # to convert the offer
    def display_offer_url(publisher_app)
      query_string = display_offer_params(publisher_app).to_query
      "#{TestChamber.target_url}/get_offers/webpage?#{query_string}"
    end

    def display_offer_params(publisher_app)
      gen_offer_params(:display_offer, publisher_app)
    end

    def conversion_url(publisher_app, options={})
      raise 'click_key is required to generate a conversion URL' unless options[:click_key]

      params = gen_offer_params(:convert_offer, publisher_app)
      params[:click_key] = options[:click_key]

      "#{TestChamber.target_url}/ad_unit/convert?data=#{ObjectEncryptor.encrypt(params)}"
    end

    def set_destination_url!(url)
      visit "#{TestChamber.target_url}/statz/#{id}/edit"
      find(:css, '#offer_url_overridden').set(true)
      find(:css, '#offer_url').set url
      select(101,:from => "offer_offer_objective_id")
      find(:css, '#offer_title').set("Test")
      find(:css, '#offer_details').set("Test")
      click_button('Save Changes', :exact => true)
    end

    def is_premium?
      TestChamber::Models::Offer.find(id).premium
    end

    private
    # Abstract method for offer creation logic
    def create!
      raise NotImplementedError
    end

    # Abstract method for offer edit logic. This method should be implemented by an editor module representing the type
    # of the offer, and the action being used to edit the offer (see TestChamber::Editor::Video::Api)
    # @param [TestChamber::Properties] properties A properties object containing all the fields and values to update for the
    #   offer.
    def edit!(properties)
      raise NotImplementedError
    end

    ## Parameters from offer, device and app
    def gen_offer_params(action, publisher_app)
      raise "publisher_app is required to generate offer parameters because an offer must be clicked and converted in the context of a publishing app showing the offer" unless publisher_app
      params = params_for(offer_params_group, action)
      params.merge!(TestChamber.current_device.params_for(offer_params_group, action))
      params.merge!(publisher_app.params_for(offer_params_group, action))
    end

    ## Parameters group is plural of snake cased class (e.g. generic_offers)
    ## Specialize this method to return specific offer parameters group
    ## e.g. MraidOffer.offer_params_group returns 'generic_offers'
    def offer_params_group
      offer_params_type.pluralize.to_sym
    end

    # This returns the click key that should be created when this offer is started. The behavior here
    # varies widely based on offer type, sdk version and tjs stripping out and replacing hardware identifiers for android 10.1 requests.
    # Still trying to figure out a consistent way to predict what the click should be. Right now normalized_id.app_id or offer_id is a reasonable default.
    def click_key
      key = "#{TestChamber.current_device.normalized_id}.#{click_key_offer_part}"

      # NOTE: Click keys with leading periods seems to happen because in tjs application_controller strips out "hardware identifiers" for android 10.1 requests
      # which included udid. But the ClickRequest class uses udid as the first part of the click key of "#{params[:udid]}.offer_id" and if its gone the
      # click key has no first part and starts with .offer_id. There are before_filters that are supposed to put values into params[:udid]
      # but they don't work in all cases. Investigating this as a bug in TJS.
      raise "invalid click key #{key}. It's very likely that some offer parameters are misconfigured #{key}" if key.start_with?('.')
      key
    end

    private

    # A click key is made up of a device identifier and an offer identifier. For install offers, the "offer" part of the click key is actually the app id of the advertiser's app
    # that needs to be installed to complete the offer. That is overridden in TestChamber::Offer::Install
    # For other offers its the offer id with the device that uniquely identifies the click.
    def click_key_offer_part
      id
    end

    def edit_url
      "#{TestChamber.target_url}/dashboard/statz/#{id}/edit"
    end

    def get_click_url(publisher_app)
      raise "A click must be completed in the context of a publishing app showing the offer, so publisher_app can't be nil" unless publisher_app
      visit display_offer_url(publisher_app)
      find(".offer-item a")["href"]
    end

    def validate_click
      Util.wait_for(60, TestChamber.default_wait_for_interval, {click_key: click_key}) do
        TestChamber::Models::Click.find(click_key)
      end
    end

    # After offer creation, set the id from content on the page
    def id_from_page
      return id unless id.nil?
      # find call that will retry to block for page load
      find_link('Edit Offer')
      attributes[:id] = page.find('#content .offer_name')[:id]
      raise "Offer not successfully created because we couldn't find the id on the page." if id.blank?
      id
    end

    # Set offer as using TPAT. Currently only works for Install Offers.
    def enable_third_party_tracking!
      unless self.is_a? TC::Offer::Install
        raise "Currently only Install offers support TPAT."
      end
      # Here we should use the @id(offer_id) but not @app_id to create the campaign, cause @app_id is actually the publisehr_app_id,
      # but the app_id we send to the third party should be the advertiser_app_id, which is the @id here
      payload = { name: self.title, app_id: @id, attribution_policy: 'immediate' }

      response = rest_request(:post, "#{TestChamber.fake_has_offers_url}/campaigns", payload: payload)
      @campaign = JSON.parse(response[:body])
      @tracking_url = campaign["unexpanded_url"]
      @campaign
    end

    # Take a click key with either a normalized device part or unnormalized and reverse that so
    # we can check to see if we are looking for a click that exists but is normalized differently than
    # we expect
    def reverse_normalization(id)
      parts = id.split('.')


      if parts.size == 1
        parts
      else
        device_part = parts[0]

        parts[0] = if device_part.include?('-')
                     Device.normalize(device_part)
                   else
                     # turn a normalized uuid back into one with dashes
                     /(.{8})(.{4})(.{4})(.{4})(.{12})/.match(device_part).to_a[1..-1].join('-')
                   end
      end
      parts.join('.')
    end

    # Uses ActionDecorator to decorate an offer with a specific creator either defined by the module param or
    # using the offer's class name and provided @create_with.  If @create_with is nil, ActionDecorator will attempt
    # to find the first available creator for the offer and uses it.
    # @param (Module) creation_module optional Provide a creation_module to decorate the offer with
    def include_creation_module(creation_module = nil)
      TestChamber::ActionDecorator.decorate(object: self, decorator: :creator, action: @create_with,
                                            action_module: creation_module)
    end

    def include_editor_module(editor_module = nil)
      TestChamber::ActionDecorator.decorate(object: self, decorator: :editor, action: @edit_with,
                                            action_module: editor_module, overwrite: true)
    end
    # include TestChamber::ObjectCache
  end
end
