# Use this for unit tests that are not running features (selenium/appium). We skip all of the slow user/partner creation
# steps. Manually require only the needed files in your actual test.

require 'active_record'
require 'active_support/hash_with_indifferent_access'
require 'pry'
require 'rspec/expectations'
require 'yaml'

RSpec.configure do |c|
  # CI Reporter doesn't play nice with .rspec files or command line options, so
  # we're including it here, AFTER everything else, so it can't blow them away.
  if ENV['CI_REPORTS']
    require 'ci/reporter/rake/rspec_loader'
    c.formatter = CI::Reporter::RSpec3::Formatter
  end
  c.alias_it_should_behave_like_to :it_validates, "validates:"
  c.filter_run :focus => true
  c.filter_run_excluding :pending => true
  c.run_all_when_everything_filtered = true
end
