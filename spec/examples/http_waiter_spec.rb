require 'spec_helper'

# This is an example of how to use TestChamber::HttpWaiter
# There are two mways to use HttpWaiter. The first is to create a new HttpWaiter and then
# assert what the `result` should be where `result` is whatever is returned from the block
# passed to the HttpWaiter constructor.
#
# The block is passed the request object and can analyze it or do whatever it likes.
# The call to `HttpWaiter#result` will block until a request is received.
#
# Alternatively :wait => true can be passed in the option hash passed to the HttpWaiter constructor.
# This means that the constructor itself should block until a request is received and any asserting
# will be done inside the block itself.
describe TestChamber::HttpWaiter do

  let(:timeout) {2999}

  it "should wait for two waiters to receive a request" do

    waiter1 = TestChamber::HttpWaiter.new(port:8180, timeout:timeout) do |request|
      request.fullpath
    end

    waiter2 = TestChamber::HttpWaiter.new(port:8181,timeout:timeout) do |request|
      request.fullpath
    end

    # in order to get the test to finish we have to run
    # curl http://localhost:8180/hello ; curl http://localhost:8181/hello
    # This simulates what the web server is waiting for the system under test to do
    Util.wait_for do
      `curl http://localhost:8180/hello`
      first = $?.exitstatus == 0
      `curl http://localhost:8181/hello`
      second = $?.exitstatus == 0
      first && second
    end

    expect(waiter1.result).to eql '/hello'
    expect(waiter2.result).to eql '/hello'
  end


  it "should wait for a request and assert" do
    # this has to be in a thread because the call to HttpWaiter.new below will block until the request is received.
    Thread.start do
      Util.wait_for do
        puts "calling"
        `curl http://localhost:8180/hello`
        $?.exitstatus == 0
      end
    end

    TestChamber::HttpWaiter.new(port:8180, timeout:timeout, wait:true) do |request|
      expect(request.fullpath).to eql '/hello'
    end
  end
end
