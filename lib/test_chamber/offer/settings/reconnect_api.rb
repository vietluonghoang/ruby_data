module TestChamber
  class Settings::ReconnectApi < Settings

    def defaults
      super.merge({
        instructions: 'Reconnect Instructions',
        objective_id: 301
      })
    end

    def supported_settings
      super.concat(%i[app_id])
    end

  end
end
