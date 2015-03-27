module TestChamber::Creator
  class App

    # Common logic needed for both V1 and V2 UI app creation
    module UiBase

      # The api and UI have different platform strings so translate them so we can find them in the UI
      def translate_platform_to_ui(platform)
        translated = {
          'android' => 'Android',
          'iphone' => 'iOS',
          'windows' => 'Windows'
        }[platform]
        unless translated
          raise "Unknown api platform '#{platform}' so we can translate it into the string on the UI"
        end
        translated
      end

      # grab the last thing in the url
      def id_from_url
        url = URI.parse(current_url)
        self.id = url.path.split('/')[-1]
        unless TestChamber::UUID.uuid?(id)
          raise "We were looking for an id in the last part of the path but it doesn't look like a uuid. id: #{id}, url: #{url}"
        end
        id
      end
    end
  end
end
