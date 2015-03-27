desc "Drops you into a pry console with test_chamber loaded and ready to use. set TC_NO_LOGIN if you want to skip dashboard login"
task :console do
  require 'spec_helper'
  require 'pry-byebug'

  load_test_chamber

  include Capybara::DSL
  binding.pry
end
