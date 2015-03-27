# == Schema Information
#
# Table name: partner_assignments
#
#  id         :string(36)      not null, primary key
#  user_id    :string(36)      not null
#  partner_id :string(36)      not null
#
module TestChamber
  module Models
    class PartnerAssignment < ActiveRecord::Base
      include UuidPrimaryKey

      self.primary_key = :id

      belongs_to :user
      belongs_to :partner
      
      delegate :name, :to => :partner
    end
  end
end