# coding: utf-8
module TestChamber
  # Wrapper object for interacting with Partners
  class Partner
    include Capybara::DSL
    include TestChamber::Rest

    DEFAULT_STARTING_BALANCE = MonetaryValue.new(10000000000, -3)

    attr_accessor :company_name
    attr_accessor :contact_name
    attr_accessor :contact_phone
    attr_accessor :id

    def initialize(options={})
      defaults = {
        :id => nil,
        :company_name => "automation-#{SecureRandom.hex(6)}",
        :reseller_id => nil,
        :discount_all_offer_types => false,
        :rev_share => nil,
        :max_deduction_percentage => nil,
        :offer_discount => nil,
        :offer_discount_expiration => nil
      }

      @raw_opts = options
      @options = defaults.merge(options)

      @company_name = @options[:company_name]
      @reseller_id = @options[:reseller_id]

      @rev_share = @options[:rev_share]
      @max_deduction_percentage = @options[:max_deduction_percentage]

      @discount_all_offer_types = @options[:discount_all_offer_types]
      @offer_discount = @options[:offer_discount]

      # whether or not to use the browser to submit the
      # create partner form or just submit it with the rest
      # client. Using the browser is incredibly slow due to
      # the redirect back to the partner list page after the
      # form is submitted.
      @use_ui = @options[:use_ui]

      # offer discount expiration is only used if offer discount is set so it
      # is safe to set for all partners.
      if @options[:offer_discount_expiration]
        @offer_discount_expiration = @options[:offer_discount_expiration]
      else
        @offer_discount_expiration = 2.days.from_now
      end
      create!
    end

    # Create and configure a partner.
    def create!
      if @options[:id]
        @id = @options[:id]
        @model = TestChamber::Models::Partner.find(@id)
      else
        # The entire partners page has to render after a new partner is created
        # before we can proceed which takes a while.
        # Just submit the form with the rest client A dirty hack
        # but we create a lot of partners so it gets very slow.
        name = @company_name
        contact_name = 'John Smith'
        phone = '827-5309'


        if @use_ui
          visit "#{TestChamber.target_url}/partners/new"
          fill_in('partner[name]', :with => name)
          fill_in('partner[contact_name]', :with => contact_name)
          fill_in('partner[contact_phone]', :with => phone)
          select("United States", :from => "partner[country]")

          Util.wait_for(5,1) { first('#partner_submit') }
          Util.trigger_click(first('#partner_submit')) do
            first('#partner_submit').nil?
          end
        else
          # yes, this is horrible, but it is VASTLY faster than using the browser to do this so when
          # we create lots of partners, like one before each test, we can use this.
          html = Nokogiri::HTML(authenticated_request(:get, "dashboard/partners/new", format: :html)[:body])

          begin
            authenticity_token = html.css("input[name=authenticity_token]")[0]["value"]
          rescue
            # Sometimes the authenticity token doesn't exist; we need to catch that situation.
            # Usually due to a redirect to the login page because user auth is not working 100% of the time.
            # Raising makes this more visible.
            raise "Didn't have the authenticity token. Html: #{html}"
          end

          submit_form_with_rest(action: "#{TestChamber.target_url}/dashboard/partners",
                                params: {'partner[name]' => name,
                                         'partner[contact_name]' => contact_name,
                                         'partner[contact_phone]' => phone,
                                         'partner[country]' => "US",
                                         'utf8' => "✓",
                                         'authenticity_token' => authenticity_token,
                                         'commit' => "Create Partner"
                                        },
                                  expected_redirect:  "#{TestChamber.target_url}/dashboard/partners")
        end

        Util.wait_for(TestChamber.default_wait_for_timeout,
                      TestChamber.default_wait_for_interval,
                      {:partner_name => @company_name, :options => @options}) do
          @model = TestChamber::Models::Partner.where(:name => @company_name).order(:created_at => :desc).first
        end

        @id = @model.id
        TestChamber.created_partners << @id

        # Set reseller_id manually since no reliable way to set via UI.
        set_reseller

        configure_partner
        approve_partner
        # cache_object

        verify_partner
      end
    end

    # I'm not sure if it ever happened but I want to make sure the partner in the DB reflects what we think
    # it should be before we pass it back.
    def verify_partner
      partner = TestChamber::Models::Partner.find(@id)
      if @rev_share
        if partner.rev_share != @rev_share
          raise "The rev_share set on the partner did not match what we set. There might have been a problem setting it. Expcected rev_share #{@rev_share}. Actual: #{partner.rev_share}: #{partner}"
        end
      end
      if @offer_discount
        discount = partner.offer_discounts.first
        unless discount
          raise "We tried to set an offer discount on a partner but no discount was found on the Partner in the DB. We tried to set the offer_discount to #{@offer_discount}:  #{partner.id}"
        end
        if discount.amount != @offer_discount
          raise "The offer_discount set on the partner did not match what we set. There might have been a problem setting it. Expcected offer_discount #{@offer_discount}. Actual: #{discount.amount}: #{partner}"
        end
        if discount.expires_on < Time.now.utc
          raise "Your offer discount on this partner is already expired so it probably isn't going to do what you want. It expired on #{discount.expires_on} and it is now #{Time.now}"
        end
      end
      if @reseller_id
        if partner.reseller_id != @reseller_id
          raise "Reseller id for partner was #{partner.reseller_id}, but we expected #{@reseller_id}."
        end
      end
    end

    # Act as a given partner for the dashboard session
    # @param partner_or_id Either a Partner to act as, or the id of one
    def self.act_as!(partner_or_id, opts={})
      # Takes a partner object or an id of a partner and acts as that partner.
      if partner_or_id.is_a?(Partner)
        id = partner_or_id.id
      else
        id = partner_or_id
      end
      Partner.new({:id => id}).act_as_partner!(opts)
    end

    def act_as_partner!(opts={})
      unless opts[:api]
        visit "#{TestChamber.target_url}/partners/#{@id}" unless page.current_url == "#{TestChamber.target_url}/partners/#{@id}"
        # meaning, unless we're already acting as that partner
        unless acts_as_partner_button_element.disabled?
          Util.trigger_click(acts_as_partner_button_element) do
            acts_as_partner_button_element.disabled?
          end
          Util.wait_for(10,1, {:partner_name => @company_name}) do
            acts_as_partner_button_element.disabled?
          end
        end
      else
        formatted_cookies = TestChamber.user_cookies.inject({}) { |memo, c| memo[c[:name]] = c[:value]; memo }
        begin
          RestClient::Request.new(
            :method => :post,
            :cookies => formatted_cookies,
            :url => "#{TestChamber.target_url}/partners/#{@id}/make_current",
            ).execute
        rescue RestClient::Found => e
          # we found the page we were looking for, move on
        end
      end
    end


    def configure_partner
      visit "#{TestChamber.target_url}/partners/#{@id}/edit"
      if @discount_all_offer_types
        find(:css, '#partner_discount_all_offer_types').set(true)
      end
      if @rev_share
        fill_in('partner[rev_share]', :with=> @rev_share)
      end
      if @max_deduction_percentage
        fill_in('partner[max_deduction_percentage]', :with=> @max_deduction_percentage)
      end

      Util.trigger_click('form input[type="submit"]') do
        # when the submit button is gone we're loading the partner list page.
        # The partner list page takes forever to load so just check if the button is gone
        first('form input[type="submit"][name="commit"][value="Update"]').nil?
      end

      set_offer_discount(@offer_discount)

      @model.monetary_balance = DEFAULT_STARTING_BALANCE
      @model.save!

    end

    def approve_partner
      @model.approved_publisher = true
      @model.save!
    end

    def balance
      response = authenticated_request(:get, "/api/client/partners/#{@id}")
      obj = JSON.parse(response[:body])
      return obj['result']['partner']['balance']
    end

    def pending_earnings
      response = authenticated_request(:get, "/api/client/partners/#{@id}")
      obj = JSON.parse(response[:body])
      return obj['result']['partner']['pending_earnings']
    end

    private

    def acts_as_partner_button_locator
      ".make_current input[type='submit']"
    end

    def acts_as_partner_button_element
      find(acts_as_partner_button_locator)
    end

    def acts_as_partner_button_element_no_wait
      first(acts_as_partner_button_locator)
    end

    def set_reseller
      @model.set_reseller(@reseller_id) if @reseller_id
    end

    def set_offer_discount(offer_discount)
      if offer_discount
        visit "#{TestChamber.target_url}/partners/#{@id}/offer_discounts"
        click_link('Create an Offer Discount')
        fill_in('offer_discount[expires_on]', :visible => true, :with=>@offer_discount_expiration)
        fill_in('offer_discount[amount]', :with=>offer_discount)

        # the datepicker modal blocks the submit button so .trigger hacks around it.
        Util.trigger_click(find(:css, '#offer_discount_submit', :visible => true)) { first('#offer_discount_submit') }
      end
    end

    # include TestChamber::ObjectCache
  end
end
