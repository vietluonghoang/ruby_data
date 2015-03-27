require 'nokogiri'
require 'open-uri'

module TestChamber
  class ActivityLog
    include Rest

    # An ActivityLog object is designed to represent a snapshot of the activity log viewer at a given instant of time.
    # This would simply query "<tjs>/dashboard/activities/<params>" with any specified parameters and hold the table that it generates
    # an array of table rows. All methods
    # If you need a current view of the activity log, create a new ActivityLog object. For example:
    #
    #     activity_log = ActivityLog.new({options})
    #
    # The options that can be provided here help filter the activity log that is to be parsed. They should be passed though as one single hash. The
    # possible parameters that can be passed are - :user, :object_id, :request_id, :partner_id, :start_date, :end_date, :object_type, :field.
    # For example:
    #
    #     activity_log = ActivityLog.new({:object_id => object.id, :partner_id => partner.id})
    #

    def initialize(options={})
      @params = options
      @n_page = Nokogiri::HTML(authenticated_request(:get,"/dashboard/activities#{parse_params}", format: :html)[:body])

      parse_activity_table_headers
      parse_activity_table
    end

    def offer_ids
      @table_data.map { |row| row["source_id"] }.compact
    end

    def modified_object_ids
      @table_data.map { |row| row["Object"] }.compact
    end

    private

    def parse_activity_table_headers
      @table_headers = @n_page.css('th').map { |header| header.text }
    end

    def parse_activity_table
      key = @table_headers.cycle

      @table_data = @n_page.css('tr').map do |tr|
        row = {}

        tr.css('td').each do |td|
          row[key.next] = parse_td_element(td)
        end

        convert_diff_to_hash(row)
      end
    end

    def parse_params
      return "" if @params.empty?
      @params.inject("?") { |str, param| str << "#{param.first}=#{param.last}&" }
    end

    def convert_diff_to_hash(row)
      records = String(row["Diff"]).scan(/(\w*):\n*([\w\-\:]+)/)

      records.each do |key, value|
        row[key] = value
      end

      row
    end

    def parse_td_element(td)
      link_under_element = td.css('a').first

      if link_under_element
        link_under_element['onclick'].split("'")[3]
      else
        td.text
      end
    end
  end
end
