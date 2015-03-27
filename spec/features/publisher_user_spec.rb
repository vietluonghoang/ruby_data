require 'spec_helper'
require 'securerandom'

describe TestChamber::PublisherUser, type: :feature do

  include_context "I am logged in"
  include_context "using the new look"

  before(:all) do
    @app = ENV['TEST_APP_ID'] ? TestChamber::App.new(id: ENV['TEST_APP_ID']) : TestChamber::App.new(platform: 'android')
  end

  let(:device) { TestChamber.current_device }

  let(:subject) do
    device.publisher_user(@app)
  end

  describe 'reward_points' do
    [:android_9_point_1_point_4, :android_10_point_0, :android_10_point_1, :android_10_point_1_point_1].each do |sdk_version|
      context "for sdk #{sdk_version}" do
        let(:device) { TestChamber::Device.send(sdk_version) }

        it 'should increase the user balance' do
          subject.award_points(50)

          balance = nil
          Util.wait_for(60) do
            balance = subject.point_balance
            expect(balance).to eql(50)
          end
        end

        # Disabled until we support web requests for apps other than TJS
        xit 'should generate a web request with the correct info' do
          test_start = Time.now
          subject.award_points(50)
          web_requests = TestChamber::WebRequest.since(test_start, :path => 'award_points')

          add_context(web_requests: web_requests)

          expect(web_requests.size).to eql(1)
        end
      end
    end

    context 'with a previously stored publisher user id on device' do
      let(:publisher_user_id) { SecureRandom.uuid }

      before(:each) do
        device.publisher_user_id = publisher_user_id
        device.create('publisher_user_ids' => {@app.id => publisher_user_id})
      end

      # Disabled until the v2 APIs are available in the device identity service
      xit 'should be able to look up balances without the publisher user id' do
        balance = nil
        subject.award_points(50)

        device.publisher_user_id = nil
        publisher_user_without_id = device.publisher_user(@app)
        Util.wait_for do
          balance = publisher_user_without_id.point_balance
          expect(balance).to eql(50)
        end
      end
    end
  end

  describe 'spend_points' do
    it 'should decrease the user balance' do
      balance = nil

      subject.award_points(50)
      Util.wait_for do
        balance = subject.point_balance
        expect(balance).to eql(50)
      end

      subject.spend_points(10)
      Util.wait_for do
        balance = subject.point_balance
        expect(balance).to eql(40)
      end
    end
  end
end
