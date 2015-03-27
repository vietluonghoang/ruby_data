require 'timeout'

# Class for defining useful utility methods
class WaitForAbort < StandardError ; end

class WaitForTimeout < StandardError
  def initialize(message="wait_for timeout expired")
    super message
  end
end

class UnsupportedSystemError < StandardError
end

class Util
  # Numeric datestamp for throwing in names to make them unique
  def self.name_datestamp
    Time.now.strftime('%Y%m%d%H%M%S%L')
  end

  # triggering a click works in some cases where clicking directly on the element
  # doesn't. Modal dialogs are an example where its in the way of the thing you
  # want to click on but you don't care. You just want to click the button.
  # However, triggering the click doesn't wait for the page to finish loading afterwards
  # This method triggers a click event on the element passed in and then runs the
  # block passed in to verify that the result of the click happened. This is usually
  # a first("#my_element") or something.
  #
  # element specified by the second locator to show up.
  #
  # thing_to_click  can either be a string of the css locator for the element
  # or the element itself.
  # The block passed in should return true when the event the page is updated correctly.

  def self.trigger_click(thing_to_click, options = {})
    begin
      tries ||= 5
      # if we get passed an element we have to just click on it. Can't trigger
      # on an element using selenium
      if thing_to_click.is_a?(String)
        Capybara.page.driver.execute_script("$('#{thing_to_click}').trigger('click')")
        sleep 0.5 # give the button a chance to do something
      else
        thing_to_click.click
        # no need to wait when calling click since it waits implicitly
      end

      # try a few times as the trigger click sometimes doesn't send the click event
      if block_given?
        raise "Block in Util.trigger_click to wait for returned false" unless yield
      end
    rescue => e
      if e.is_a?(Selenium::WebDriver::Error::StaleElementReferenceError)
      # This means that the button we are clicking on is gone so the page
      # was submitted. Nothing more to do and no more reason to wait.
      elsif (tries -= 1) > 0
        sleep 1
        retry
      else
        raise e
      end
    end
  end

  # Wait a specified timeout for the given block to return. Try again every given interval
  #
  # This method is inteded to be used with  blocks that are awaiting the result of some async process
  # such as waiting for an object to be created in the db or interacting with elements on a web page.
  # It should no be used on blocks that will execute long running blocking operations.
  #
  # @param timeout [Fixnum] Number of seconds total to wait for the block to return. Default 30
  # @param interval [Fixnum] Interval to wait between trying block for a return value. Default 2
  # @param debugging [Hash] A hash of values which will be printed out if the wait_for times out.

  def self.wait_for(timeout = TestChamber.default_wait_for_timeout,
                    interval = TestChamber.default_wait_for_interval,
                    debugging = nil)
    start_time = Time.now
    end_time = start_time + timeout
    raised_exception = nil
    block_result = nil
    times = 0
    begin
      loop do
        begin
          raise WaitForTimeout if Time.now > end_time
          times += 1
          block_result = yield
          break if block_result
          sleep interval
        rescue StandardError,RSpec::Expectations::ExpectationNotMetError => e
          if e.is_a?(WaitForAbort) || e.is_a?(WaitForTimeout)
            raise e
          end
          raised_exception = e
          sleep interval
          next
        ensure
          if times > 3
            puts "Still waiting on block #{get_caller} #{times} times"
          end
        end
      end
    rescue WaitForTimeout => e
      template = "

The block passed to wait_for at #{start_time} timed out at #{Time.now} after waiting for #{timeout} seconds.

It was called from #{get_caller}

<% if debugging %>
The debugging information passed in with the block: #{debugging}
<% end

if raised_exception
  formatted_exception = raised_exception.backtrace * \"\n\"
%>
An exception was raised at least once: '<%= raised_exception %>'

Stack trace:

<%= formatted_exception %>
<% end %>"
      e.message << ERB.new(template).result(binding)
      raise e
    end
    block_result
  end

  # Get the first stack grame that isn't the junk leading up to Util.wait_for so we can
  # print out where we started waiting from.
  def self.get_caller
    Kernel.caller.find do |frame|
      ! frame.include?("pry") &&
        ! frame.include?("test_chamber/util.rb") &&
        ! frame.include?("timeout.rb")
    end
  end

  def self.exec_in_new_terminal cmd
    case `uname`.chomp
    when 'Darwin' then `osascript -e 'tell app "Terminal" to do script "#{cmd}"'`
    when 'Linux' then `x-terminal-emulator -e #{cmd}`
    else
      raise UnsupportedSystemError, <<-DOC
        OS not recognized.
        Cannot automatically launch process in new terminal.
      DOC
    end
  end
end
