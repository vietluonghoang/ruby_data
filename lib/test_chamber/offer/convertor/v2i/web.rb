module TestChamber::Convertor
  module V2I

    # Just here for the dynamic extending of the Offer class.
    module Web
      include TestChamber::Convertor::Video::Web
    end

  end
end
