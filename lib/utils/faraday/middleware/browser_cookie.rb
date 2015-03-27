module TestChamber
  module Rest

    # Faraday middleware that will take the cookies from the selenium session
    #   and include them in the cookie jar
    class BrowserCookie < Faraday::Middleware

      def initialize(app, options = {})
        super(app)
        @jar = options[:jar] || HTTP::CookieJar.new 
      end

      def call(request_env)
        if TestChamber.user_cookies
          # We end up with a duplicate spirra cookie, probably from the update to
          # Dashboard#refresh_browser_cookies
          # TODO Update this when 5rocks login works
          duplicate_spirra_cookies = @jar.find_all {|c| c.name == "_spirra" && c.domain == "tapjoy.net"}
          duplicate_spirra_cookies.each {|c| @jar.delete(c)}


          TestChamber.user_cookies.each do |c|
            updated_cookie = if c.key?(:expiry) || c.key?(:expires)
              if c.key?(:expiry) && c[:expiry]
                c.merge(expires: Time.at(c[:expiry]))
              elsif c.key?(:expires) && c[:expires]
                c.merge(expires: Time.at(c[:expires]))
              else 
                c
              end
            else
              c
            end
            @jar.add(HTTP::Cookie.new(updated_cookie))
          end
        end
        @app.call(request_env)
      end
    end

  end
end
