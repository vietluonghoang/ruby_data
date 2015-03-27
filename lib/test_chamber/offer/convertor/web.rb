module TestChamber::Convertor
  module Web

    def convert_with_rest!(publisher_app, params={})
      url = conversion_url(publisher_app, click_key: (params[:click_key] || click_key))

      begin
        rest_request(:get, url)
      rescue => e
        e.message << " Exception GETing conversion_url #{url}"
        raise e
      end
    end

    def do_conversion!(publisher_app, params={})
      raise "A conversion must be completed in the context of a publishing app showing the offer, so publisher_app can't be nil" unless publisher_app
      actual_click_key = params[:click_key] || click_key
      raise "invalid click key #{actual_click_key}. It's very likely that some offer parameters are misconfigured #{actual_click_key}" if actual_click_key.start_with?('.')
      convert_with_rest!(publisher_app, click_key: actual_click_key)
    end
  end
end

