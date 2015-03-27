module TestChamber
  module Models
    class RoleAssignment < ActiveRecord::Base
      self.primary_key = :id
      belongs_to :user
      belongs_to :user_role
      validates_presence_of :id
      validates_uniqueness_of :id

      before_validation :set_primary_key, :on => :create

      # ensures that each new record has a UUID assigned to the 'id' field.
      def set_primary_key
        self.id = SecureRandom.uuid unless (id && id.uuid?)
        true
      end


    end
  end
end

