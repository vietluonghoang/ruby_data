module TestChamber
  class Reseller

    attr_accessor :id

    def initialize(options={})
      defaults = {
        :reseller_rev_share => nil
      }

      options = defaults.merge(options)

      @id = SecureRandom.uuid

      reseller = TestChamber::Models::Reseller.new

      # ID has to be a uuid. TJS uses UuidPrimaryKey to do this, but that
      # modules doesn't do anything special so we'll just make our own.
      reseller.id = @id
      reseller.reseller_rev_share = options[:reseller_rev_share]

      # Both resellers in the system now use a 0.75 rev_share. I think this is a no-op
      reseller.rev_share = 0.75
      reseller.name = "TC Reseller"
      reseller.save!
    end
  end
end
