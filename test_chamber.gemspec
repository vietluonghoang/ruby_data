$LOAD_PATH.unshift 'lib'
require "test_chamber/version"

Gem::Specification.new do |s|
  s.name              = "test_chamber"
  s.version           = TestChamber::Version::STRING
  s.date              = "2014-11-20"
  s.summary           = "Integration test drivers and helpers"
  s.homepage          = "http://github.com/Tapjoy/test_chamber"
  s.email             = "tools@tapjoy.com"
  s.authors           = [ "Tapjoy Internal Tools" ]
  s.licenses          = [ "Private" ]
  s.has_rdoc          = false
  s.executables       << "test-chamber"

  s.files             = %w( README.md Rakefile )
  s.files            += Dir.glob("bin/*")
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("spec/**/*")
  s.files            += Dir.glob("assets/**/*")
  s.files            += Dir.glob("config/**/*")
  s.files            += Dir.glob("tasks/**/*")

  s.description       = "Automated integration test drivers and spec helpers for Tapjoy"

  s.add_runtime_dependency('jenkins_api_client', '~> 1.2')
  s.add_runtime_dependency('rake',    '~> 10.3')
  s.add_runtime_dependency('git',    '~> 1.2')
  s.add_runtime_dependency('dynamiq-ruby-client', '~> 1')
  s.add_runtime_dependency('yard', '~> 0')
  s.add_runtime_dependency('parallel_tests', '~> 1')

end
