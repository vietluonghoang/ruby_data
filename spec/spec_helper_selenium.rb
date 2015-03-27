require 'selenium-webdriver'

Capybara.register_driver :selenium do |app|
  ## Firefox profiles allow us to control specific configuration and extension options
  ## As well as install extensions themselves.  Each time Selenium launches a FF browser
  ## it creates a clean profile.  We can create a profile object and pass it to Selenium
  ## to override this default profile with our own options
  ## TODO: Abstract this out to a ruby class and manage the various settings using Configliere and YAML
  profile = Selenium::WebDriver::Firefox::Profile.new

  ## The 'focusmanager.testmode' setting allows us to inject blur events to a FF browser
  ## that is running in the background.  FF is expected to ignore any focus related events
  ## when the browser is running in the background.
  profile['focusmanager.testmode'] = true
  ## load_no_focus_lib allows for background focus behavior in a *nix environment.
  profile.load_no_focus_lib = true

  Capybara::Selenium::Driver.new(app, :browser => :firefox, profile: profile)

end
