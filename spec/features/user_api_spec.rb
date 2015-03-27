require 'spec_helper'

describe TestChamber::UserAPI do

  let(:is_super_user) {true}
  let(:email_address) { nil }
  let(:time_zone) { "(GMT-10:00) Hawaii" }
  let(:country) { "Viet Nam" }
  let(:language) { "en" }
  let(:is_advertiser) { "0" }
  let(:is_publisher) { "0" }
  let(:company_name) { "SGS" }
  let(:password) { "m00ncak3" }
  let(:confirm_password) { "m00ncak3" }
  let(:agree_terms_of_service) { "1" }

  let(:user_api) do
    TestChamber::UserAPI.new(
      :is_super_user => is_super_user,
      :email_address => email_address,
      :time_zone => time_zone,
      :country => country,
      :password => password,
      :confirm_password => confirm_password,
      :is_advertiser => is_advertiser,
      :is_publisher => is_publisher,
      :agree_terms_of_service => agree_terms_of_service,
      :language => language,
      :company_name => company_name,
    )
  end

  before(:each) do 
    user_api.create!
  end

  context "Add new user via API " do
    let(:is_super_user) { false }
    let(:email_address) { "sgsTestAddAPI#{Time.now.strftime('%Y%m%d%H%M%S%L')}@testt.com" }
    
    it "successfully" do
      json = user_api.fetch
      expect(json["email"]).to eql email_address
    end
  end

  context "Update user details via API" do
    let(:email_address) { "sgsTestEditAPI1#{Time.now.strftime('%Y%m%d%H%M%S%L')}@testt.com" }
    let(:updated_email_address) { "sgsTestEditAPI1#{Time.now.strftime('%Y%m%d%H%M%S%L')}@testt.com" }

    it "successfully" do
      json = user_api.fetch
      expect(json["email"]).to eql email_address
      user_api.email_address = updated_email_address
      user_api.update!

      json = user_api.fetch
      expect(json["email"]).to eql updated_email_address
    end
  end
  
  context "When creating new super user via API with valid email address" do
    let(:is_super_user) { true }
    let(:email_address) { "sgsTestRegisterAPI#{Time.now.strftime('%Y%m%d%H%M%S%L')}@testt.com" }

    it " creates a super user via API successfully" do
      json = user_api.fetch
      expect(json["email"]).to eql email_address
    end
  end

 end