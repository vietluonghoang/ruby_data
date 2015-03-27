require 'bundler'
require 'rubygems'
require 'rake'
require 'yard'
require 'parallel_tests/tasks'

$: << File.join(File.dirname(__FILE__), 'spec')
$: << File.join(File.dirname(__FILE__), 'lib')

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)

# load 'rails/tasks/engine.rake'

Dir[File.join(File.dirname(__FILE__), 'tasks/**/*.rake')].each {|f| load f }
require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc "Run all specs in spec directory (excluding plugin specs)"
task :default => :spec

RSpec::Core::RakeTask.new('spec:unit') do |t|
  ENV['TC_NO_BROWSER'] = "true"
  t.pattern = './spec/unit/*_spec.rb'
  t.rspec_opts = "--tag unit"
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
end

