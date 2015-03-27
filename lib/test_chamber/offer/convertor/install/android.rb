module TestChamber::Convertor
  module Install
    module Android

      # Install over conversions are the same as web because we just send a
      # connect call and we can't really install apps on the simulator/devices.
      include TestChamber::Convertor::Install::Web
    end
  end
end
