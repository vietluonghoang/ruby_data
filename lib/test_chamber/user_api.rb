# coding: utf-8
module TestChamber
  class UserAPI < User
    attr_accessor :id
    
    def initialize(options={})
      super(options)
    end

    def create_super_user!
      raise "You can't create a user if its already been created. Id is already #{id}" if id
      # Since the value of "authenticity_token" variable does not effect the result of registration process,
      # we hard-code it.
      authenticity_token = "ue7sQiFEjK71OZIYRqeLPwPig5/qlnAfMcuwUIcnuaE="

      payload = {
        "utf8" => '✓',
        "authenticity_token" => authenticity_token,
        "user[email]" => @email_address,
        "partner_name" => @company_name,
        "user[password]" => @password,
        "user[password_confirmation]" => @confirm_password,
        "user[time_zone]" => @time_zone,
        "user[country]" => @country,
        "user[preferred_language]" => @language,
        "user[account_type_advertiser]" => @is_advertiser,
        "user[account_type_publisher]" => @is_publisher,
        "user[term_of_service]" => @agree_terms_of_service,
        "commit" => "Create Account"
      }
      response = rest_request(:post, "dashboard/register", payload: payload, format: :html)
      # the user id is kept in the user credentials cookie. Because this isn't
      # a real api but a rails controller we have to dig around to find the id
      # The user_credentials cookie is a long url encoded hex string with two colons
      # followed by the user id. CGI.parse returns a hash with the whole mess in the
      # key. So we take that, split on the colons and get the id at the end
      @id = CGI.parse(response[:cookies]["user_credentials"]).first[0].split(':')[-1]
    end

    def create_normal_user!
      raise "You can't create a user if its already been created. Id is already #{id}" if id
      payload = {
        :email => @email_address,
        :time_zone => @time_zone,
        :country => @country,
        :user => {
          :email => @email_address,
          :time_zone => @time_zone,
          :country => @country
        }
      }

      create_api_response = authenticated_request(:post, "api/client/partners/#{TestChamber.default_partner_id}/users", payload: payload)
      create_api_body = JSON.parse(create_api_response[:body])["result"].first[1]
      @id = create_api_body['id']
    end

    def fetch
      unless id
        raise "user can not be updated before it is created."
      end

      response = authenticated_request(:get, "api/client/users/#{id}")
      JSON.parse(response[:body])["result"].first[1]
    end
    
    # update normal user via API
    def update!
      unless id
        raise "user can not be updated before it is created."
      end
      hash = "W10="

      payload = {
        "id" => id,
        "email" => @email_address,
        "time_zone" => @time_zone,
        "country" => @country,
        "preferred_language" => @language,
        "receive_campaign_emails" => "true",
        "hash" => hash,
        "username" => @email_address,
        "last_login_at" => get_last_login_at!,
        "password" => @password,
        "password_confirmation" => @confirm_password,
        "user" => {
          "email" => @email_address,
          "password" => @password,
          "password_confirmation" => @confirm_password,
          "time_zone" => @time_zone,
          "receive_campaign_emails" => "true",
          "country" => @country,
          "preferred_language" => @language
        }
      }

      response = authenticated_request(:put, "api/client/users/#{id}", payload: payload)
      response[:status]
    end

    def get_last_login_at!
      payload = { :page => 1 }
      response = authenticated_request(:get, "/api/client/partners/#{TestChamber.default_partner_id}/users", payload: payload)

      obj = JSON.parse(response[:body])
      object = obj['result']['users'].first
      @last_login_at = object['user']['last_login_at']

      @last_login_at
    end
  end
end
