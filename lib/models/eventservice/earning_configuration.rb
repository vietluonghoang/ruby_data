module TestChamber
  module Models
    module EventService
      class EarningConfiguration < EventsDbBase
        self.primary_key = :id

        belongs_to :placement
      end
    end
  end
end
