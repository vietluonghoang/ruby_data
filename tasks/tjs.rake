# Usage: 
#   foreman run bundle exec rake generate_devices[num_devices,num_workers,app_id]
#     num_devices - the number of devices you wish to generate
#     num_workers - the number of workers generating devices, optional defaults to 20
#     app_id      - the id of the application to use for the connect call, optional defaults to App.first
#
# This should generaate about 1000 devices/minute with 20 workers. 
desc "This task is used to generate devices in a TIAB"
task :generate_devices, [:num_devices, :num_workers, :app_id] do |t, args|

  ENV["TC_NO_BROWSER"] = true.to_s
  ENV["TC_NO_LOGIN"] = true.to_s

  require 'spec_helper'

  args.with_defaults(num_workers: 20)

  total_devices = args[:num_devices].to_i
  num_workers = args[:num_workers].to_i
  app_id = args[:app_id]
  app_id ||= TestChamber::Models::App.first.id

  device_ids = generate_devices(TestChamber::App.new(:id => app_id), total_devices, num_workers)
  write_device_file(device_ids)
end

def generate_devices(app, total_devices, num_workers)
  devices_per_worker = total_devices / num_workers
  devices_remainder = total_devices % num_workers

  puts "Total Devices: #{total_devices}, Workers: #{num_workers}, Devices/Worker: #{devices_per_worker}, App: #{app.id}"
  threads = (0...num_workers).map do |i|
    num_devices = i == 0 ? devices_per_worker + devices_remainder : devices_per_worker
    Thread.new(app, num_devices, &worker) 
  end

  threads.each(&:join)
  threads.flat_map { |t| t[:device_ids] }
end

def worker
  Proc.new do |app, num_devices|
    puts "Starting worker to create #{num_devices} devices..."
    Thread.current[:device_ids] = [] 
    num_devices.times do
      device = TestChamber::Device.new
      app.open_app(device) 
      Thread.current[:device_ids] << device.udid
    end
    puts "Worker created #{num_devices} devices"
  end 
end

def write_device_file(device_ids)
  require 'csv'
  CSV.open('device_ids.csv', 'w') do |csv|
    device_ids.each { |id| csv << [id] }
  end
end
