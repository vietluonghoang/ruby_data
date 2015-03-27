module TestChamber::AppiumClient
  class Local
    attr_reader :target_url, :app_path, :app_name, :ext

    def initialize
      @target_url = TestChamber::Config[:target_url]
      @app_path = TestChamber::Config[:appium][:app_path]
      @app_name, @ext = app_path.match(/([-\w]+)(\.\w+)$/)[1..2]
    end

    def configure
      start_appium_server
      check_tiab_pointer

      configure_local
    end

    protected

    def urls_match?
      searchable_file.include?(target_url)
    end

    def build_target_url
      match = searchable_file.match(/http:\/\/[-\w\d]+-tapinabox.tapjoy.net/i)
      match ? match[0] : "No tapinabox URL found in the SDK"
    end

    def unzip_file(app_path, target_file)
      Zip::File.open(app_path) do |zip_file| # Handles .zip/.apk files
        entry = zip_file.find { |entry| target_file == entry.name }
        entry.get_input_stream.read
      end
    end

    def searchable_file
      raise NotImplementedError, <<-DOC
        #searchable_file is implemented by AppiumClient::Android and AppiumClient::IOS modules.
        Make sure that you've included the appropriate module for your device type.
      DOC
    end

    private

    def check_tiab_pointer
      return if urls_match?

      raise_configuration_error <<-DOC
        #{app_name} is built for wrong TIAB.
        Make sure target_url in test_chamber/.env matches your sdk build.
        Target URL: #{target_url}
        Build URL: #{build_target_url}
        App path: #{app_path}
      DOC
    end

    def start_appium_server
      appium_server_url = TestChamber::Config[:appium][:cmd_exec] ||
                          'http://localhost:4723/wd/hub'
      conn = Faraday.new(url: appium_server_url)
      port = appium_server_url.match(/:(\d+)\/wd\/hub$/)[1]

      begin
        begin
          conn.get
        rescue Faraday::ConnectionFailed
          Util.exec_in_new_terminal("appium -p #{port} --session-override")
        end
      rescue UnsupportedSystemError
        raise_configuration_error <<-DOC
          Could not launch appium server in new terminal.
          Launch appium server manually and run the specs again.
          https://github.com/Tapjoy/test_chamber/blob/develop/docs/appium.md#-running-locally
        DOC
      end
    end
  end
end
