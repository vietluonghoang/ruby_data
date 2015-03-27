require 'sauce_whisk'

module TestChamber
  class SauceLabsClient
    include SauceWhisk

    def upload_app(app_path)
      storage = SauceWhisk::Storage.new(
        :username => TestChamber::Config[:saucelabs][:username],
        :key      => TestChamber::Config[:saucelabs][:access_key],
        :debug    => true
      )
      storage.upload app_path
      # needs to return the filename as that's what is sent in desired caps
      File.basename app_path
    end
  end
end
