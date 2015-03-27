module TestChamber::Convertor
  module TPAT
    def do_conversion!(*args)
      response = rest_request(:get, "#{TestChamber.fake_has_offers_url}/campaigns/#{@campaign["id"]}/convert")
      @campaign = JSON.parse(response[:body])
    end
  end
end
