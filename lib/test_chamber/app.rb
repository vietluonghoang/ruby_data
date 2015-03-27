module TestChamber
  # Wrapper class for Apps
  class App
    include UniqueName
    include Capybara::DSL
    include TestChamber::Rest
    include TestChamber::OfferParams
    include TestChamber::Creator::InstanceMethods
    include TestChamber::Properties::InstanceMethods

    extend Gem::Deprecate

    IOS_EASY_APP_ID = '13b0ae6a-8516-4405-9dcf-fe4e526486b2'
    ANDROID_EASY_APP_ID = 'bba49f11-b87f-4c0f-9632-21aa810dd6f1'

    attr_accessor :rewarded_currency_ids

    # Create a new app or return an app from cache.
    #
    # @param attributes [Properties, Hash] Will accept a Properties object or a hash
    #   which will be used to create a Properties object
    # @return [App] The newly created App
    def initialize(attributes={})
      self.attributes = wrap_attributes(attributes, :create_with)

      if self.rev_share_override != 0.5 && self.create_with != :ui_v1
        puts "Warning: Overriding create_with of '#{self.create_with}' to"\
              " 'ui_v1' because no other app creation method supports creating"\
              " currencies with revshare overrides"
        self.create_with :ui_v1
      end

      @create_with = self.create_with
      include_creation_module(self.creator_module)

      unless %w{android iphone}.include? platform
        raise "expected platform to be one of [android, iphone, windows], but got #{platform}"
      end
      self.rewarded_currency_ids = []

      if id.present?
        merge_record
      else
        create!
        # add the default currency
        self.rewarded_currency_ids << id

        # set this so offer_params can use it when we make conversion requests as we have to specify the currency
        self.currency_id = create_currency(currency_name || 'Coins')
        self.rewarded_currency_ids << currency_id

        create_non_rewarded_currency if self.attributes.create_non_rewarded_currency

        add_to_apps_network if apps_network_id
        validate_app
        # cache_object
      end

      unless TestChamber::UUID.uuid? id
        raise 'App creation failed, could not determine UUID'
      end
    end

    # Alternative constructor that is used with the EasyApp.
    # @param os [Symbol] The operating system (ios, android) to use for the easy_app. This defaults to the value from
    #   appium.yml.
    # @return [self] An instance of TestChamber::App.
    # @raise [ArgumentError] If os is nil (because no os is set in appium.yml) will raise ArgumentError.
    def self.easy_app(os=TC::Config[:appium][:os])
      case os.to_sym
      when :ios
        self.new(id: IOS_EASY_APP_ID)
      when :android
        self.new(id: ANDROID_EASY_APP_ID)
      else
        raise ArgumentError, "Cannot create an App for EasyApp unless you specify an OS. Either set an OS in appium.yml"\
          " or pass an OS as an argument."
      end
    end

    def record(reload: false)
      if @record.nil?
        reload = false # don't reload if we don't have the model yet
      end
      @record ||= TestChamber::Models::App.find(id)
      @record.reload if reload
      @record
    end

    def merge_record
      attributes.merge!(record.attributes)
      record.currencies.each do |curr|
        self.rewarded_currency_ids << curr.id if curr.rewarded?
        self.currency_id = self.rewarded_currency_ids.first
      end
    end

    def option_defaults
      {
        :name => "test-chamber-app_#{name_datestamp}",
        :partner_id => TestChamber.default_partner_id,
        :apps_network_id => nil,
        rev_share_override: nil,
        :create_non_rewarded_currency => false,
        :platform => 'android',
        :state => 'live',
        version: (1..[3,4].sample).map { rand(10) }.join('.'),
        bridge_version: "1.0.3",
      }
    end


    # Look into the database and see if we created everything the right way.
    def validate_app
      model = Util.wait_for(10,1,{:app_id => id}) { record }
      raise "Unable to find db record for new app #{id}" unless model


      # Check the app was created by the right partner.
      unless partner_id == model.partner_id
        raise "Partner id on new app model doesn't match the one we thought "\
              "we were 'acting as' when we created the app. We were passed "\
              "#{partner_id} and the model had #{model.partner_id}"
      end

      rewarded_currency_ids.each do |currency|
        currency_model = TestChamber::Models::Currency.find(currency)
        raise "Unable to find db record for currency #{currency}" unless currency_model

        unless currency_model.app_id == id
          raise "Currency #{currency} created for wrong app; expected #{id} "\
                "but currency was created for #{currency_model.app_id}"
        end

        unless currency_model.tapjoy_enabled
          raise "Currency #{currency} is not enabled."
        end

        unless currency_model.partner_id == partner_id
          raise "Currency #{currency} created for wrong app; expected "\
                "#{partner_id} but currency was created for "\
                "#{currency_model.partner_id}"
        end

        unless currency_model.rev_share_override.to_f == rev_share_override.to_f
          raise "Currency #{currency} using wrong revshare override; expected"\
                " #{rev_share_override.to_f} but using "\
                "#{currency_model.rev_share_override.to_f}"
        end
      end
    end

    # Open an offerwall with this app as the publishing app showing the offerwall using TestChamber.current_device
    # as the device
    def offerwall
      TestChamber::Offerwall.new(app: self)
    end

    # simulate the opening of an app on a device. This will result in a connect call
    def open_app(device=TestChamber.current_device)
      # When making a connect call the :app_id parameter is the id of the app being opened and
      # making the connect call. In a PPI situation the offer that is clicked on, usually in the
      # offerwall, creates a click with <device_id>.<advertiser_app_id> as the click_key indicating
      # that the offer has been initiated.  To complete the offer the user has to open the app whose
      # :advertising_app_id was in the click.  When the connect call comes in from opening the app
      # the user was supposed to install to complete the offer it will try to find an existing click
      # with a key <udid>.<app_id> so those have to match the click we initiated with
      # offer.complete_click.
      rest_request(:get, connect_url(device), format: :html)
    end

    # Click on an offer with this app as the publishing app showing the offer
    # @deprecated Please use Offerwall#click_offer instead.
    def click_offer(offer)
      offer.complete_click(self)
    end
    deprecate :click_offer, :offerwall, 2015, 03

    # Convert the offer with this app as the publishing app showing the offer
    # @deprecated Please use Offerwall#click_offer.convert! instead.
    def convert_offer(offer)
      offer.complete_conversion(self)
    end
    deprecate :convert_offer, :offerwall, 2015, 03

    # Builds a publisher user represented by the given unique user id within
    # this app.  If you don't know what the user id is -- and have a device --
    # then use `PublisherUser.new` directly and pass in the device.
    def publisher_user(user_id)
      PublisherUser.new(:app => self, :user_id => user_id)
    end

    def url
      "#{TestChamber.target_url}/dashboard/apps/#{id}"
    end

    private

    def create!
      raise NotImplementedError
    end

    def connect_url(device=TestChamber.current_device)
      "#{TestChamber.target_url}/connect?#{connect_params(device).to_query}"
    end

    def connect_params(device=TestChamber.current_device)
      device.query_params.merge({
                                                      app_id: id,
                                                      app_version: version,
                                                      bridge_version: bridge_version
                                                    })
    end

    # Uses ActionDecorator to decorate an offer with a specific creator either defined by the module param or
    # using the offer's class name and provided @create_with.  If @create_with is nil, ActionDecorator will attempt
    # to find the first available creator for the offer and uses it.
    # @param (Module) creation_module optional Provide a creation_module to decorate the offer with
    def include_creation_module(creation_module = nil)
      TestChamber::ActionDecorator.decorate(object: self, decorator: :creator, action: @create_with,
                                            action_module: creation_module)
    end
    # include TestChamber::ObjectCache
  end

  class V2AppCreationError < StandardError; end
end
