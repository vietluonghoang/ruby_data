# coding: utf-8
module TestChamber
  class User

    include Capybara::DSL
    include TestChamber::Rest
    include TestChamber::DashboardUtility::DSL

    attr_accessor :is_super_user
    attr_accessor :email_address
    attr_accessor :company_name
    attr_accessor :password
    attr_accessor :confirm_password
    attr_accessor :time_zone
    attr_accessor :country
    attr_accessor :language
    attr_accessor :is_advertiser
    attr_accessor :is_publisher
    attr_accessor :agree_terms_of_service
    attr_accessor :receive_campaign_emails
    attr_accessor :messages
    attr_accessor :create_account_success

    def initialize(options={})
      @is_super_user = options[:is_super_user]
      @email_address = options[:email_address]
      @company_name = options[:company_name]
      @password = options[:password]
      @confirm_password = options[:confirm_password]
      @time_zone = options[:time_zone]
      @country = options[:country]
      @language = options[:language]
      @is_advertiser = options[:is_advertiser]
      @is_publisher = options[:is_publisher]
      @agree_terms_of_service = options[:agree_terms_of_service]
      @receive_campaign_emails = options[:receive_campaign_emails]
    end

    def create!
      if @is_super_user
        create_super_user!
      else
        create_normal_user!
      end
    end

    def update!
      raise NotImplementedError "update! method needs to be implemented in the subclasses"
    end

    def create_super_user!
      raise NotImplementedError "create_super_user! method needs to be implemented in the subclasses"
    end

    def create_normal_user!
      raise NotImplementedError "create_normal_user! method needs to be implemented in the subclasses"
    end
  end
end