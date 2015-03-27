module TestChamber
  class Statz
    include TestChamber::Login
    include TestChamber::Rest

    # Global statz for all partners, platforms, etc
    def global_statz
      global_url = 'dashboard/statz/global.json'
      global_url << '?date=&end_date=03%2F13%2F2014&granularity=hourly&platform=all&store_name='

      response = rest_request(:get, global_url)
      JSON.parse(response[:body])
    end

    #Enter time details something like this " Time.now.strftime "%m/%d/%Y" "
    #Pass the dateTime object in start and end dates
    def offer_statz(offer_id, start_date, end_date)
      offer_url = "dashboard/statz/#{offer_id}.json"
      offer_url << "?date=#{start_date.strftime("%m/%d/%Y")}"
      offer_url << "&end_date=#{end_date.strftime("%m/%d/%Y")}"
      offer_url << "&granularity=hourly"

      response = rest_request(:get, offer_url)
      JSON.parse(response[:body])
    end

    private

    def parse_click_totals(statz_data)
      statz_data["data"]["rewarded_installs_plus_spend_data"]["main"]["totals"][1]
    end

    def parse_conversion_totals(statz_data)
      statz_data["data"]["rewarded_installs_plus_spend_data"]["main"]["totals"][0]
    end
  end
end
