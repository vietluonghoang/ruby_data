require 'utils/json_set_field'

DB_TAG_TJS='tapjoyserver'
DB_TAG_EVENTS='eventservice'

dbconfig = YAML::load(File.open('config/database.yml'))
dbconfig[DB_TAG_TJS]["host"] = dbconfig[DB_TAG_EVENTS]["host"] = URI.parse(ENV["TARGET_URL"]).host

TAPJOY_DB = dbconfig[DB_TAG_TJS]
EVENTS_DB = dbconfig[DB_TAG_EVENTS]

begin
  ActiveRecord::Base.establish_connection(TAPJOY_DB)
  ActiveRecord::Base.clear_cache!
rescue Exception => e
  # Jenkins nodes must connect to MySQL on the private IP of the host
  # due to security group restrictions. If we can't connect here,
  # discover the private IP and attempt to connect again
  begin
    host_public_ip = `dig +short #{TAPJOY_DB["host"]}`.chomp
    instance_hash = JSON.parse(`aws ec2 describe-instances --filters Name=ip-address,Values=#{host_public_ip}`)
    # Yes this is a little ugly, but that's what aws gives us.
    host_private_ip = instance_hash["Reservations"][0]["Instances"][0]["PrivateIpAddress"]
    TAPJOY_DB['host'] = host_private_ip
    ActiveRecord::Base.establish_connection(TAPJOY_DB)
  rescue Exception => ex
    puts "There was an issue connecting to your TIAB's MySQL instance at #{TAPJOY_DB['host']}"
    puts "You might need to check your aws cli configuration or make sure you're connected to the VPN"
    puts "MySQL on TIAB are only accessable from the offices, VPN, or jenkins-node boxes"
    puts "It's also possible that your box got auto-shot, you should make sure it still lives."
    puts "The public IP of the box you tried was #{host_public_ip}"
    puts "The private IP of the box you tried was #{host_private_ip}" if host_private_ip
    puts "The output from aws-cli was #{instance_hash}" if instance_hash
    puts "The exception from MySQL was #{ex.to_s}" if ex.instance_of? Mysql::Error
    exit(1)
  end
end
