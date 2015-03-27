require 'rspec/core/rake_task'
require 'yaml'

namespace :spec do
  namespace :manual do
    task :matrix, [:first] do |_, args|
      default_pattern = FileList['spec/examples/example*_spec.rb']
      supported_devices = YAML.load_file('config/manual_devices.yml')
      local_versions = `xcodebuild -showsdks`.scan(/Simulator - iOS (\S{3,5})/).flatten

      missing_versions = []
      tested_devices = []
      untested_devices = []

      supported_devices.each do |device, models|
        models.each do |model, versions|
          supported_versions = versions & local_versions
          unsupported_versions = versions - local_versions
          missing_versions |= unsupported_versions

          supported_versions.each do |version|
            ENV['APPIUM_OS'] = 'ios'
            ENV['APPIUM_VERSION'] = version
            ENV['APPIUM_DEVICE'] = "#{device} #{model}"

            spec_group = RSpec::Core::RakeTask.new

            # Check if first argument contains RSpec flag.
            # Otherwise, assume it is a valid spec_group pattern.
            # If no arguments provided, use default pattern.
            if args[:first] =~ /^--/
              spec_group.pattern = default_pattern
              spec_group.rspec_opts = args.extras << args[:first]
            else
              spec_group.pattern = args[:first] || default_pattern
              spec_group.rspec_opts = args.extras
            end

            spec_group.run_task(true)
          end

          tested_devices << [device, model, supported_versions]
          untested_devices << [device, model, unsupported_versions]
        end
      end

      puts <<-DOC
        Tested Devices: #{tested_devices}\n
        Untested Devices: #{untested_devices}\n
        Locally installed sdk verions: #{local_versions}
        Install sdk versions #{missing_versions} for complete coverage.
      DOC
    end
  end
end
