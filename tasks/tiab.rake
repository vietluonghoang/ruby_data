require 'dynamiq/client'
namespace :tiab do
  def aws_cli(command)
    `aws sqs --region us-east-1 #{command}`
  end

  def target_url
    unless ENV['TARGET_URL']
      raise "\n\nThe TARGET_URL evironment variable needs to be set to your TIAB.\n\n"
    end
    ENV['TARGET_URL']
  end

  def target_url_prefix
    URI.parse(target_url).hostname.split('-tapinabox')[0]
  end

  def queue_attributes(queue_url)
    @queues_attributes ||= {}
    unless @queues_attributes[queue_url]
      print "."
      @queues_attributes[queue_url] = JSON.parse(aws_cli "get-queue-attributes --attribute-names ApproximateNumberOfMessagesNotVisible ApproximateNumberOfMessages --queue-url #{queue_url}")["Attributes"]
    end
    @queues_attributes[queue_url]
  end

  def available_message_count(queue_url)
    queue_attributes(queue_url)["ApproximateNumberOfMessages"].to_i
  end

  def in_flight_message_count(queue_url)
    queue_attributes(queue_url)["ApproximateNumberOfMessagesNotVisible"].to_i
  end

  def queue_urls

    queue_prefix = "tapinabox_#{target_url_prefix}"
    puts "Looking for queues with prefix #{queue_prefix}"
    queue_json = aws_cli "list-queues --region us-east-1 --queue-name-prefix #{queue_prefix}"
    begin
      @queues ||= JSON.parse(queue_json)["QueueUrls"]
    rescue => e
      e.message << "\nThe JSON we tried to parse was '#{queue_json}'"
      raise e
    end
  end

  namespace :sqs do

    desc "Do all the things necessary to configure queues for use on tiab"
    task :configure_queues => [:set_queue_retention] do

    end

    desc "Check to see if any queues for the TARGET_URL have available messages in them. A lot of these can mean that no jobs are being processed"
    task :queue_details do
      puts "Fetching queue attributes to see which queues have available messages that are not currently being processed"
      counts = {}
      threads = []
      queue_urls.each do |q|
        threads << Thread.new do
          available = available_message_count(q)
          in_flight = in_flight_message_count(q)
          if available > 0 || in_flight > 0
            counts[q] = [available, in_flight]
          end
        end
      end

      threads.each(&:join)

      puts ""
      if counts.size > 0
        puts "Available | In Flight | Queue"
        queue_counts = counts.sort_by{|_key, value| -value[0]}

        queue_counts.each do |q,counts|
          puts "    #{"%5d" % counts[0]} |     #{"%5d" % counts[1]} |  #{q}"
        end
      else
        puts "No messages are currently available in any queue. This usually means messages are being processed normally"
      end
    end

    desc "Set default message retention period on all queues for TARGET_URL tiab to be 10 minutes. This prevents queues from filling up with old broken jobs."
    task :set_queue_retention do
      threads = []
      threads << queue_urls.each do |q|
        threads << Thread.new do
          aws_cli "set-queue-attributes --queue-url #{q} --attributes MessageRetentionPeriod=300"
          puts "Set MessageRetentionPeriod for #{q} to 300 seconds."
        end
      end
      threads.each(&:join)
    end
  end

  namespace :dynamiq do
    def dynamiq
      dynamiq ||= Dynamiq::Client.new(target_url,8081)
    end

    def dynamiq_queues
      queues = dynamiq.known_queues
      if queues.empty?
        puts "No dynamiq queues were found on '#{target_url}'"
      end
      queues
    end

    desc "Get the details of all known queues and display them"
    task :queue_details do
      queues = {}
      threads = []
      dynamiq_queues.each do |q|
        threads << Thread.new do
          queues[q] = dynamiq.queue_details(q)
        end

      end
      threads.each(&:join)

      puts ""

      Hash[queues.sort].each do |name, details|
        puts "#{name} : #{details}"
      end
    end

    desc "Do all the things necessary to configure Dynamiq queues for use on tiab

Configuring Dynamiq has a number of considerations

In Dyanamiq once a partition delivers a message, any other messages in that
partition are not going to get delivered until VISIBILITY_TIMEOUT has passed
even if the delivered messages are done being processed.
So with small numbers of dynamiq partitions (configured by set_partition_limits task) we could
get into a place where messages are in 'queue' and nothing is happening
because we're waiting for the timeout on a locked partition that happens
to have new messages. New messages are put into random partitions when
enqueued.
The more partitions we have the less likely a message will be in a locked
partition, but we only check one partition per poll for messages so we
might have to wait as long as POLL_INTERVAL * NUM_OF_PARTITIONS to get
a message in a random partition even without locking. On average half of that.

So we set VISIBILITY_TIMEOUT and MIN/MAX_PARITITIONS for every queue.

Visibility timeout actually effects a number of behaviors in dynamiq and chore.

- How long a given partition will remain locked after delivering a batch of messages.
- How long chore will wait before killing a worker that hasn't finished a job yet. Its actually BATCH_SIZE * VISIBILITY_TIMEOUT but on tiab BATCH_SIZE = 1.

So we have to balance what this setting is. We don't want it so low that jobs
time out, but if its too high we'll end up with lots of locked partitions and
generally sluggish job delivery to tiab.
All of these considerations are per queue. Partitions are not shared across
queues so locked partitions for a queue only effect other messages in that
queue.
"
    task :configure_queues => [:set_partition_limits, :set_visibility_timeouts] do

    end

    desc "Set the number of partitions on all queues for TARGET_URL tiab to range between 2 and 50. This a balance between how long it takes to get a message in a random
partition, and the changes of a new message being delivered to a locked partition"
    task :set_partition_limits do
      MIN_PARTITIONS = 2
      MAX_PARTITIONS = 50
      threads = []
      mutex = Mutex.new
      dynamiq_queues.each do |q|
        threads << Thread.new do
          mutex.synchronize { puts "setting #{q} to have min_partitions #{MIN_PARTITIONS}, max_partitions #{MAX_PARTITIONS}" }
          dynamiq.configure_queue(q, {min_partitions: MIN_PARTITIONS, max_partitions: MAX_PARTITIONS})
        end
      end
      threads.each(&:join)
    end

    desc "Set default message visibility timeout period on most queues for TARGET_URL tiab to be 5 seconds. This prevents partitions from being locked too long."
    task :set_visibility_timeouts do
      VISIBILITY_TIMEOUT = 10
      threads = []
      mutex = Mutex.new
      dynamiq_queues.each do |q|
        unless q.index("stats") # we don't wanna set it for stats  queues, they're slow
          threads << Thread.new do
            mutex.synchronize { puts "setting #{q} to have visibility_timeout #{VISIBILITY_TIMEOUT}" }
            dynamiq.configure_queue(q, {visibility_timeout: VISIBILITY_TIMEOUT}) unless q.index("stats")
          end
        end

      end
      threads.each(&:join)
    end
  end
end
