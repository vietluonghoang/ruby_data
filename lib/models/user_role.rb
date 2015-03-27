module TestChamber
  module Models
    class UserRole < ActiveRecord::Base
      self.primary_key = :id

      validates_uniqueness_of :name

      has_many :role_assignments
      has_many :users, :through => :role_assignments

      def admin?
        name == 'admin'
      end
    end
  end
end

