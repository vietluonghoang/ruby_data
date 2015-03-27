require 'rest_client'
require 'json'

module TestChamber
  class WebRequest

    # Defaults to 5 minutes ago as you'll likely want to see what was just caused by your test
    def self.latest
      since(5.minutes.ago)
    end
    # Returns an array of hashes that are web_request for the given time range.
    # e.g. WebRequests.since(10.minutes.ago)
    def self.since(start_time, options = {})
      # parse the files that contain the time range we're looking for
      requests = files_containing_start_time(web_request_files, start_time).map do |f|
        RestClient.get("#{TestChamber.target_url}/tmp/#{f.filename}").lines.map do |line|
          JSON.parse(line)
        end
      end.flatten
      
      # now just ge the requests for the time period
      requests.select! do |request|
        Time.at(request['attrs']['time'].first.to_f) >= start_time
      end

      if options[:path]
        requests.select! do |wr|
          wr["attrs"]["path"].include?(options[:path])
        end
      end
      if options[:app_id]
        requests.select! do |req|
          req['attrs']['app_id'].first == options[:app_id]
        end
      end

      requests
    end

    private

    # files are flushed and rotated every 15 seconds so getting any that were created
    # within 30 seconds of when we want we are sure to get all of the files with
    # events requested
    def self.files_containing_start_time(files, start_time)
      cutoff = (start_time - 60).beginning_of_minute
      files.select{ |f| f.date >= cutoff }
    end

    def self.web_request_files
      files = RestClient.get("#{TestChamber.target_url}/tmp/").split("\r\n").map do |line|
        if line.include?('analytics')
          _, anchor, date, time, size = line.split
          filename = anchor.split('"')[1]
          if filename.include?("analytics") && size.to_i > 0
            date = Time.parse("#{date} #{time}:00 UTC")
            WebRequestFile.new(filename, date)
          end
        end
      end
      files.compact
    end
  end

  class WebRequestFile

    attr_accessor :filename
    attr_accessor :date

    def initialize(filename, date)
      @filename = filename
      @date = date
    end
  end
end
