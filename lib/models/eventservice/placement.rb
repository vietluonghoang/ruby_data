module TestChamber
  module Models
    module EventService
      class Placement < EventsDbBase
        self.primary_key = :id

        has_many :earning_configurations
      end
    end
  end
end
