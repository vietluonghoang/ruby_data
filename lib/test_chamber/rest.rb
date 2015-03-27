module TestChamber
  module Rest
    class UnauthorizedRequestError < StandardError; end

    include Capybara::DSL

    LOGIN_PATTERN = /\/login\??/

    @@jar = HTTP::CookieJar.new

    # This method makes an API request to the desired endpoint
    # params:
    #   method - the http method (:get|:post|:put|:delete)
    #   route - the request path
    #   payload - a hash of the request payload
    #   format - the format of the request body (:json|:hmtl|:xml|:file)
    #            this will be used to set content-type headers and handle marshalling
    #   retry_login - flag to enable login retry
    #   expected_redirect - the url of an expected redirect from a 3xx response
    #
    #   returns - a hash containing the reponse details
    #     {
    #       :body => the repsone body as a string,
    #       :status => the response code as an int,
    #       :headers => a hash of the response headers,
    #       :cookies => a hash of the session cookies
    #     }
    #
    # example:
    #  class MyClass
    #    include TestChamber::Rest
    #    ...
    #    rest_request(:post, "api/client/apps/#{app_id}/placements/#{placement_id}", payload: payload, format: :json)
    #
    def rest_request(method, route, payload: nil, format: :json,
                     retry_login: true, expected_redirect: nil)
      max_retries, previous_page, retry_count = 2, nil, 0

      begin


        response = connection(format).send(method) do |req|
          if route.is_a?(String)
            req.url(URI.parse(route))
          else
            req.url(route)
          end
          req.body = prepare_payload(payload, format)
        end

        validate_redirect(response, expected_redirect)

        previous_page = nil

      rescue UnauthorizedRequestError => e
        # Unauthorized error will come from rest_request execution when the result is a redirect
        # to the login page.  The exception is when the request itself is to the login page (login attempts).
        # Rescue the exception and attempt to clear cookies and login restoring the cookies.  Then run the
        # same request again up to 'max_retries' times

        # Sometimes the user is not in the db. Catch that case.
        unless TestChamber::Models::User.where(:email => ENV['TEST_USERNAME'])
          raise "User #{ENV['TEST_USERNAME']} is not in db!"
        end
        if retry_login
          if current_url !~ LOGIN_PATTERN
            previous_page = current_url
            validate_browser_state
          end
          # Clear cookies to force logout
          page.driver.browser.manage.delete_all_cookies
          @@jar.clear
          # Try to login and execute the request once more, persist the current_url
          # as we want to return if login works
          if retry_count < max_retries
            puts "logged out on request, UI login attempt ##{retry_count+=1}, #{e}"
            Capybara.current_session.driver.quit
            TestChamber::Dashboard.new.ui_login
            retry
          end
        end
        raise e
      rescue => e
        response = (e.respond_to?(:response)) ? e.response : e
        raise e, "encountered exception for #{route}, response: #{response}", e.backtrace
      end

      # previous page will be set if a login attempt was successful
      visit previous_page unless previous_page.nil?

      # convert the Faraday response to a Hash of simple data
      # this avoids leaking Faraday implementation details to consumers
      {
        :body => response.body,
        :headers => response.headers.to_hash,
        :cookies => get_cookies,
        :status => response.status
      }
    end

    # This method makes an authenticated API request to the desired endpoint, which
    # is most useful for the /api/client endpoints that dashboard v2 uses to communicate
    # with TJS.
    #
    # example:
    #  class MyClass
    #    include TestChamber::Rest
    #    ...
    #    authenticated_request(:post, "api/client/apps/#{app_id}/placements/#{placement_id}", payload)
    #
    def authenticated_request(method, route, payload: nil, format: :json)
      rest_request(method, route, payload: payload, format: format)
    end

    # This method submits a form on a page by scraping the contents
    # of all input elements in the form and posting to the forms
    # action with the authenticated RestClient.
    #
    # This can be used in cases when submitted the form redirects
    # to a page that takes an outrageously long time to render (I'm looking at you partner list page)
    #
    # form parameter is the form element
    def submit_form_with_rest(form_element: nil, action: nil, params: nil, expected_redirect: nil)
      if form_element.nil? && ( action.nil? && params.nil?)
        raise "Must pass in either a form element to submit or an action url with a parameters hash"
      end

      if form_element
        params = form_element.all(:css, "input").inject({}){|result, input| result[input["name"]] = input.value ; result }
        action = form_element["action"]
      end

      rest_request(:post, action, payload: params, format: :html, retry_login: true, expected_redirect: expected_redirect)
    end

    def generate_verifier(params, more_data = [])
      app = TestChamber::Models::App.find(params[:app_id])
      hash_bits = [
        params[:app_id],
        params[:udid] || params[:mac_address] || params[:advertising_id] || params[:android_id],
        params[:timestamp],
        app.secret_key
      ] + more_data
      Digest::SHA256.hexdigest(hash_bits.join(':'))
    end

    private

    def connection(format=:json)
      Faraday.new(:url => TestChamber.target_url) do |builder|

        # adds selenium cookies to rest module's cookie jar
        builder.use TestChamber::Rest::BrowserCookie, jar: @@jar

        # handles cookies for requests
        builder.use :cookie_jar, jar: @@jar

        # makes 400/500 responses go KABOOM!!!!
        builder.use Faraday::Response::RaiseError

        # sets content-type header and marshalls payload
        if format == :json
          builder.request :json
        elsif format == :xml
          builder.use TestChamber::Rest::RequestXml
        elsif format == :html
          builder.request :url_encoded
        elsif format == :file
          builder.request :multipart
        elsif format == :multipart
          builder.request :multipart
        else
          raise "Unknown rest request format type '#{format}'"
        end

        builder.adapter Faraday.default_adapter
      end
    end

    def get_cookies
      cookies = {}
      @@jar.each do |cookie|
        cookies[cookie.name] = cookie.value
      end
      cookies
    end

    def prepare_payload(payload, format)
      if format == :file
        { file: Faraday::UploadIO.new(payload[:file], payload[:content_type], payload[:filename]) }
      else
        if payload.is_a?(Hash)
          # Set fields do not work well with Faraday, so force them to arrays
          payload.each do |key, value|
            if value.is_a?(Set)
              payload[key] = value.to_a
            end
          end
        end

        payload
      end
    end

    def validate_browser_state
      visit '/dashboard/partners/new'
      if current_url =~ LOGIN_PATTERN
        if page.driver.browser.cookie_named('_spirra')[:value].include?('+')
          raise "Browser is logged out and spirra cookie value contains invalid '+' character"
        end
        raise "Browser is logged out but spirra cookie does not contain invalid '+' character"
      end
    end

    def validate_redirect(response, expected_redirect)
      # 4xx/5xx handled by RaiseError middleware
      if [301, 302, 307].include? response.status
        location = response.headers["location"]
        if expected_redirect
          raise "Rest request expected a redirect to #{expected_redirect}, but was sent to #{location}" if expected_redirect != location
        else

          if location =~ /\/login\??/ && response.env.url.to_s !~ /\/dashboard\/user_sessions/
            raise UnauthorizedRequestError, "rest_request redirected to login page, response_details: #{response.inspect}"
          end
        end
      elsif expected_redirect # must be a 1xx/2xx
        raise "Rest request expected a redirect to #{expected_redirect}, but was not redirected"
      end
    end
  end
end
