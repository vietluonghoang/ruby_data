require 'spec_helper'

describe 'A Mobile Device' do

  before do
    TestChamber.current_device = device
  end

  let(:black_listed_properties) do
    [:mac_address, :android_id, :udid]
  end
  let(:publisher_app) { TestChamber::App.new(publisher_app_params) }
  let(:publisher_app_params) { {} }
  let(:device_ident_key) { }
  let(:device_identifier) do
    TestChamber::Models::DeviceIdentifier.find(device_ident_key)
  end
  let(:device_key) { device.normalized_id }
  let(:device_model) { TestChamber::Models::Device.find(device_key) }
  let(:device_params) { {android_id: true} }
  subject(:device) do
    TestChamber::Device.android_10_point_1(device_params)
  end

  context "running Android" do
    let(:platform) { 'android' }
    let(:publisher_app_params) { { platform: platform} }

    context "with an App originally integrated with SDK 10.1" do

      # These are properties that, under no circumstances, should we be storing on the device
      # There are other properties that have explicit tests, but those relate to the merge process
      # and are present to more explicitly make sure no data was merged between devices. These are more
      # simple "ignore these if they came in with the connect call" params.

      context "makes a connect call" do
        before do
          publisher_app.open_app
        end

        context "and a new Device record is created" do
          let(:advertising_id) { device.advertising_id }
          let(:normalized_advertising_id) { advertising_id.gsub(/-/,"") }
          let(:device_ident_key) { normalized_advertising_id }
          let(:device_publisher_users) do
            device_model.attribute('publisher_user_ids')
          end

          it "does not have a DeviceIdentifier record created" do
            expect(device_identifier).to be_nil
          end

          it "has the advertising_id set" do
            expect(device_model.attribute('advertising_id')).to eq normalized_advertising_id
          end

          it "has the advertising_id as the key" do
            expect(device_model.key).to eq normalized_advertising_id
          end

          it "does not have an upgraded_idfa" do
            expect(device_model.attribute('upgraded_idfa')).to be_nil
          end

          it "does not store blacklisted propertes on the device" do
            black_listed_properties.each do |property|
              expect(device_model.attribute(property.to_s)).to be_nil
            end
          end

          context "when an open_udid is provided" do
            let(:open_udid) { ConnectRequestData.open_udid }
            let(:device_params) { {open_udid: open_udid, android_id: true} }
            let(:secondary_id_mappings) do
              device_model.attribute('secondary_id_mappings')
            end

            it "has open_udid mapped in secondary_id_mappings" do
              expect(secondary_id_mappings['open_udid']).to eql open_udid
            end
          end

          context "when a publisher_user_id is supplied" do
            let(:publisher_user_id) { device.publisher_user_id }
            let(:device_params) { {publisher_user_id: true, android_id: true} }

            it "ignores it in the connect call, and instead uses the advertising_id" do
              # Reviewed this behavior with other engineers, appears to be the case
              # PUID gets put onto device via separate API call
              expect(device_publisher_users[publisher_app.id]).
                  to eql(publisher_user_id)
            end
          end

          context "when a publisher_user_id is not supplied" do
            context "but an install_id is" do
              let(:install_id) { SecureRandom.hex(32) }
              let(:device_params) do
                {install_id: install_id, publisher_user_id: false,
                 android_id: true}
              end

              it "uses the install_id as the publisher_user_id" do
                expect(device_publisher_users[publisher_app.id]).
                    to eql(install_id)
              end
            end
            context "and no install_id is" do
              let(:device_params) do
                {install_id: nil, publisher_user_id: nil, android_id: true}
              end
              # It's my understanding this is not possible with this SDK version
              # I'll leave the test in, but might should be refactored
              it "uses the advertising_id as the publisher_user_id" do
                # For older SDKs where we could pass in a udid and keep it on the device
                # this would be the udid, and not the advertising id
                expect(device_publisher_users[publisher_app.id]).
                    to eql(device_model.attribute('advertising_id'))
              end

              context "and no udid is" do
                let(:device_params) do
                  {install_id: nil, publisher_user_id: nil, udid: nil,
                   android_id: true}
                end
                it "uses the advertising_id as the publisher_user_id" do
                  expect(device_publisher_users[publisher_app.id]).
                      to eql(normalized_advertising_id)
                end
              end
            end
          end

          context "when a publisher user id is not provided, but a second connect call comes in with one" do
            let(:device_params) { {publisher_user_id: nil, android_id: true} }
            let(:reloaded_device) do
              TestChamber::Models::Device.find(device_model.key)
            end
            let(:device_publisher_users) do
              reloaded_device.attribute('publisher_user_ids')
            end
            it "updates the publisher user id on the device" do
              device.publisher_user_id = ConnectRequestData.publisher_user_id
              publisher_app.open_app
              expect(device_publisher_users[publisher_app.id]).
                  to eql(device.publisher_user_id)
            end
          end

          context "when there was an existing device record" do
            # For each of the connect request configurations prior to 10.1
            [:android_9_point_1_point_4, :android_10_point_0, :android_10_point_1].each do |legacy_sdk|
              context "from sdk #{legacy_sdk}" do
                let(:legacy_device) do
                  TestChamber::Device.send(legacy_sdk, device_params)
                end

                context "and that existing device had no PointPurchase balance for this App" do
                  let(:point_purchase) do
                    publisher_user_id, app_id = device.publisher_user_id, publisher_app.id
                    TestChamber::Models::PointPurchase.find("#{publisher_user_id}.#{app_id}")
                  end
                  it "the new device has no PointPurchase balance" do
                    # connect call for current
                    expect(point_purchase).to be_nil
                  end
                end
                context "and that existing device had a PointPurchase balance for this App" do

                  before do
                    TestChamber.current_device = legacy_device
                    publisher_app.open_app
                    legacy_publisher_user.award_points(reward_amount)
                    Util.wait_for(60) do
                      @legacy_points = legacy_publisher_user.point_balance
                    end

                    TestChamber.current_device = device
                    publisher_app.open_app
                    Util.wait_for(60) do
                      @current_points = publisher_user.point_balance
                    end
                  end

                  let(:reward_amount) { 100 }
                  let(:legacy_publisher_user) do
                    TestChamber::PublisherUser.new(app: publisher_app,
                                                   device: legacy_device)
                  end
                  let(:publisher_user) do
                    TestChamber::PublisherUser.new(app: publisher_app,
                                                   device: device)
                  end

                  it "the new device copies the balance from the old device" do
                    expect(@legacy_points).to eql(@current_points)
                  end
                end
              end
            end
          end

          context "when there was no existing device record" do
            let(:device_publisher_users) do
              device_model.attribute('publisher_user_ids')
            end
            let(:publisher_user_id) { device_publisher_users[publisher_app.id] }
            let(:point_purchase_key) { "#{publisher_user_id}.#{publisher_app.id}" }
            let(:point_purchase) do
              TestChamber::Models::PointPurchase.find(point_purchase_key)
            end

            it "the new device has no PointPurchase balance" do
              expect(point_purchase).to be_nil
            end
          end
        end
      end

      context "requests the offerwall" do

        let(:offerwall) { TestChamber::Offerwall.new(app: publisher_app) }

        context "and offers have already been completed" do

          before do
            TestChamber::OptSOA.set_top_offers([offer.id])
            offerwall.click_offer(offer.id).convert!
            # Wait for the item_id to aggregate in the riak device model
            Util.wait_for do
              offer.complete?
            end
          end

          let(:other_device) do
            TestChamber::Device.android_10_point_0(device_params)
          end
          let(:offer) { TestChamber::Offer::Video.new }

          it "hides the offer on the current device but displays on other device" do
            reloaded_offerwall = TestChamber::Offerwall.new(app: publisher_app)
            add_context({reloaded_offer_ids: reloaded_offerwall.offer_ids})
            expect(reloaded_offerwall.offer_ids).to_not include(offer.id)
            # There could be value breaking this into historical advertising/android/mac address
            # style devices, but all three should behave identically.
            TestChamber.current_device = other_device
            publisher_app.open_app
            TestChamber::OptSOA.set_top_offers([offer.id])
            reloaded_offerwall = TestChamber::Offerwall.new(app: publisher_app)
            add_context({other_device_reloaded_offer_ids: reloaded_offerwall.offer_ids})
            expect(reloaded_offerwall.offer_ids).to include(offer.id)
          end
        end

        # These are x-ed out because we cannot properly test them with TestChamber at the moment.
        # It requires a little more sophistication around how conversion urls are generated and setting up
        # currencies with server side redirects, which we'd then need to test.
        context "a given offer displayed on the offerwall" do

          before do
            publisher_app.open_app
          end

          let(:offerwall) do
            TestChamber::Offerwall.new(app: publisher_app)
          end
          let(:offer) do
            offerwall.offers.first
          end
          let(:conversion_url_params) do
            # TODO How do we get a conversion_url directly from TJS for
            # testing this behavior?
          end
          let(:advertising_id) { device.advertising_id }

          xit "does not include black listed properties in the callback url" do
            black_listed_properties.each do |prop|
              expect(conversion_url_params.keys).to_not include(prop)
            end
          end

          xit "does include a macro for advertising_id in the callback_url" do
            expect(conversion_url_params['advertising_id']).to eql(advertising_id)
          end
        end

        context "and clicks a PPI offer" do

          before do
            publisher_app.open_app
            offerwall.click_offer(offer.id)
          end

          let(:offer) do
            offerwall.offers.find do |offer|
              offer.item_type == "App"
            end
          end
          let(:click) do
            TestChamber::Models::Click.find(offer.send(:click_key))
          end

          it "creates a click record" do
            expect(click).to_not be_nil
          end

          context "and completes the offer" do
            before do
              offerwall.convert_offer(offer.id)
            end

            let(:device_publisher_users) do
              device_model.attribute('publisher_user_ids')
            end
            let(:conversion) do
              TestChamber::Models::Conversion.find(click.attribute('reward_key'))
            end
            let(:reward) do
              TestChamber::Models::Reward.find(click.attribute('reward_key'))
            end
            let(:point_purchase) do
              key, model = "#{device_publisher_users[publisher_app.id]}."+
                  "#{publisher_app.id}"
              purchase = nil
              Util.wait_for do
                purchase = TestChamber::Models::PointPurchase.find(key)
              end
              purchase
            end

            it "creates a conversion" do
              expect(conversion).to_not be_nil
            end

            it "creates a reward" do
              expect(reward).to_not be_nil
            end

            it "results in the devices PointPurchase balance being credited the amount specified by the reward" do
              expect(point_purchase).to_not be_nil
            end
          end

          # This test appears to be nonsense. It doesn't just change the SDK version but also changes the device identifier,
          # so it can't really be surprising that it can't find the click.
          context "and upgrades to a later SDK before completing the offer" do

            before do
              TestChamber.current_device.library_version = "10.1.1"
              offerwall.convert_offer(offer.id)
            end

            subject(:device) do
              normalized_id = TestChamber::Device.normalize(SecureRandom.uuid)
              device_params.merge!(advertising_id: normalized_id)
              TestChamber::Device.android_9_point_1_point_4(device_params)
            end

            let(:point_purchase) do
              key = "#{device_publisher_users[publisher_app.id]}.#{publisher_app.id}"
              purchase = nil
              Util.wait_for do
                purchase = TestChamber::Models::PointPurchase.find(key)
              end
              purchase
            end
            let(:device_publisher_users) do
              device_model.attribute('publisher_user_ids')
            end

            xit "rewards the new PointPurchase record under the new device" do
              expect(point_purchase).to_not be_nil
            end
          end
        end
      end
    end

    # This test should be fixed once we abstract SDKs to the right layer (app).
    [:android_9_point_1_point_4, :android_10_point_0].each do |sdk|
      context "with an App using SDK #{sdk}" do
        context "opens the offerwall" do

          before do
            action_offer.enable
            TestChamber::OptSOA.set_top_offers([action_offer.id], device_id: :all)
          end

          after do
            ## TODO: It would be convenient to have a 'reset' for fake-opt-SOA
            offer_id = TestChamber::Models::Offer.first.id
            TestChamber::OptSOA.set_top_offers([offer_id], device_id: :all)
          end

          subject(:device) do
            TestChamber::Device.send(sdk, device_params)
          end
          let(:device_params) do
            { publisher_user_id: true, android_id: true, open_udid: nil}
          end
          let(:offerwall) { TestChamber::Offerwall.new(app: publisher_app) }
          let(:action_app) { TestChamber::App.new }
          let(:action_offer) do
            marquee_img_path = File.join('assets/300x250_image.png')
            icon_path = File.join('assets/generictest.png')

            TestChamber::Offer::Action.new(id: action_app.id,
                marquee_preview_image_path: marquee_img_path,
                icon_path: icon_path, background_path: marquee_img_path,
                video_url: 'http://test-video.foo/video', name: 'action-video',
                app_id: action_app.id)
          end
          let(:offer) do
            offerwall.offers.find do |offer|
              offer.id == action_offer.id
            end
          end
          let(:offer_model) do
            TestChamber::Models.find(offer.id)
          end
          let(:conversion) do
            TestChamber::Models::Conversion.find(click.attribute('reward_key'))
          end
          let(:click) do
            TestChamber::Models::Click.find(click_key)
          end
          let(:click_key) do
            "#{device.udid}.#{offer.id}"
          end

          xit "can see CPA offers for apps using SDK 10.1" do
            expect(offer).to_not be_nil
          end

          xit "can convert CPA offers for apps using SDK 10.1" do
            offerwall.click_offer(offer.id)

            # TODO: Use offerwall.convert_offer(offer.id) once click_key
            # creation is consistent with TJS.
            offer.complete_conversion(publisher_app, click_key: click_key)
            expect(conversion).to_not be_nil
          end
        end
      end
    end
  end
end
