require 'sinatra/base'

module TestChamber
  class HttpWaiter

    def initialize(opts = {}, &block)
      @expectation_block = block
      @port = opts[:port] || '8181'
      @timeout = opts[:timeout] || 30
      listen(@port)

      result if opts[:wait]
    end

    def result
      begin
        Timeout.timeout(@timeout) do
          @server_thread.join
        end
      rescue Timeout::Error => e
        e.message << "\nWe waited for #{@timeout} seconds for an HTTP call on port #{@port} but none was forthcoming."
        raise e
      end
      block_result
    end

    def block_result
      raise @block_result if @block_result.is_a?(Exception)
      @block_result
    end

    # Once the result is set the listening webserver is shut down. This allows the thread
    # to exit. If we call #result before the thread exits it will block and then join when
    # the result of the block is set.
    def block_result=(block_result)
      @block_result = block_result
      stop_server
    end

    def yield(args)
      @expectation_block.yield(args)
    end

    private

    def listen(port)

      @web_server = nil

      @server_thread = Thread.start do
        sinatra_server = ExpectantWebServer.new(self)
        rack_app = Rack::Builder.app do
          map '/' do
            run sinatra_server
          end
        end

        start_server(rack_app, port)
      end
    end

    def start_server(app, port)
      begin
        @rack = Rack::Server.new({
                                   app:    app,
                                   server: 'webrick',
                                   Host:   '0.0.0.0',
                                   Port:   port
                                 })
        # grab the instance of thin since rack provides no way to shut down the server
        # besides SIGINT
        @rack.start do |server|
          @web_server = server
        end
      rescue => e
        if e.message == "no acceptor (port is in use or requires root privileges)"
          puts "

***Warning***

It looks like you started two #{self.class}s on the same port #{port}.
If you're going to use two #{self.class}s at a time you have to specify different ports
for each one like:

waiter1 = #{self.class}.new
waiter2 = #{self.class}.new
waiter1.listen(:port => 8181) do |request|
  #stuff
end
waiter2.listen(:port => 8182) do |request|
  #see how the ports are different?
end

waiter1.wait_for
waiter2.wait_for

"
        else
          puts "Exception starting rack server #{e}\n#{e.backtrace * "\n"}"
        end
      end
    end

    def stop_server
      raise "The server wasn't started but you tried to stop it" unless @web_server
      @web_server.stop
    end


  end

  # Simple sinatra app that listens for all paths and calls the block waiter to do whatever
  # it wants with the request.
  class ExpectantWebServer < Sinatra::Base
    def initialize(waiter)
      @waiter = waiter
      super
    end

    # threaded - False: Will take requests on the reactor thread
    #            True:  Will queue request for background thread
    configure do
      set :threaded, false
    end

    # Request runs on the reactor thread (with threaded set to false)
    get '/*' do
      begin
        @waiter.block_result = @waiter.yield request
      rescue => e
        @waiter.block_result = e
      end
    end

  end
end