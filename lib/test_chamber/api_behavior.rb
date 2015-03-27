# Common logic to create objects using the V2 admin API. Offers, Apps, Currencies etc
module TestChamber::ApiBehavior
  include TestChamber::Rest

  attr_reader :response_code

  def create_with_api(override_payload = nil)
    pl = override_payload || create_payload
    @create_api_response = authenticated_request(:post, create_api_endpoint, payload: pl, format: format)

    # The response is JSON with a single top level key called
    # video_ad or install_ad or something. All the interesting stuff is
    # under that key.

    @create_api_body = JSON.parse(@create_api_response[:body])["result"].first[1]
    @response_code = @create_api_response[:status]
    @create_api_response
  end

  # Some controller endpoints on tjs don't support PUT yet. Those that do can use this
  # method but the ones where PUT is not implemented on the server will receive a 500 error
  def update_with_api(update_payload, format = nil)
    format ||= self.format
    response = authenticated_request(:put, "#{update_api_endpoint}/#{id}", payload: update_payload, format: format)
    response_body = JSON.parse(response[:body])
    unless [200, 202].include?(response_body['status'])
      raise "Error updating #{self.class} #{id}. Response #{response[:status]} - #{response}"
    end
    response
  end

  def id_from_page
    return @id unless @id.nil?
    if @create_api_body
      self.id = @create_api_body["id"]
    else
      raise "We didn't find a response from calling the create api so we can't figure out the id of this object."
    end
  end

  def create_api_endpoint
    raise NotImplementedError "create_api_endpoint must be implemented in the includer of this module"
  end

  def update_api_endpoint
    raise NotImplementedError "update_api_endpoint must be implemented in the includer of this module"
  end

  def create_payload
    raise NotImplementedError "create_payload method must be implemented in the includer of this module"
  end

  def edit_payload(attributes)
    raise NotImplementedError "edit_payload method must be implemented in the includer of this module"
  end

  # By default send json to the api endpoint
  #   Override this method in the including class to send another format
  def format
    :json
  end
end
