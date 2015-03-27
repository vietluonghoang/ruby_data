# Matcher to assert that web requests containing the hash of properties passed in
# were found in the subject.
# Usage:
#    TestChamber::WebRequest.latest.should contain_web_requests_like({:path => "offers",
#                                                                      :app_id => "13b0ae6a-8516-4405-9dcf-fe4e526486b2"}).times(2)
RSpec::Matchers.define :contain_web_requests_like do |expected|
  match do |actual|
    @matches = actual.select do |web_request|
      expected.all? do |expected_key, expected_value|
        actual_value = web_request['attrs'][expected_key.to_s]

        # actual value is always an array even though they almost always contain one value
        # If expected_value is not an array, then check it against first element in actual_value

        if expected_value.is_a?(Array)
          expected_value == actual_value
        else
          actual_value.include?(expected_value) if actual_value
        end
      end
    end

    if @times
      @matches.size == @times
    else
      @matches.size > 0
    end
  end


  chain :times do |times|
    @times = times
  end


  failure_message do |actual|

    if actual && actual.size > 0
      message = "Out of #{actual.size} web requests in the time frame we found #{@matches.size} but we really wanted to find #{@times} of them."
      message << "\nWe wanted them to look like #{expected}"
      if actual.size > 0
        message << "\nHere are the ones we found.\n\n#{actual}"
      end
    else
      message = "There were no web requests found in the time range specified."
    end
    message
  end
end
