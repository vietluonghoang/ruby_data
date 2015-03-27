module TestChamber
  module Models
    class User < ActiveRecord::Base
      self.primary_key = :id
      has_many :role_assignments, :dependent => :destroy
      has_many :user_roles, :through => :role_assignments
      has_many :partner_assignments
      has_many :partners, :through => :partner_assignments
    end
  end
end

