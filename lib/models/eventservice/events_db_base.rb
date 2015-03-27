module TestChamber
  module Models
    module EventService
      class EventsDbBase < ActiveRecord::Base
        self.abstract_class = true
        establish_connection EVENTS_DB
      end
    end
  end
end

