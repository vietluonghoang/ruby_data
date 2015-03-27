require 'spec_helper'
require 'securerandom'

describe 'PlacementService:PlacementsApi' do
  Placement = TestChamber::PlacementService::Placement
  Action    = TestChamber::PlacementService::Action
  AdAction  = TestChamber::PlacementService::AdAction
  MmAction  = TestChamber::PlacementService::MmAction

  let!(:app_id)               { SecureRandom.uuid }
  let(:invalid_app_id)        { SecureRandom.uuid }
  let(:invalid_placement_id)  { SecureRandom.uuid }


  def create_placement(options={})
    code, p = Placement.post(Placement.new(options).payload)
    p
  end

  def create_action(klazz, options={})
    code, a = klazz.post(klazz.new(options).payload)
    a
  end

  def verify_placement_content(orig, recv)
    expect(recv["id"]).to   eql(orig["id"])
    expect(recv["name"]).to eql(orig["name"])
    expect(recv["description"]).to eql(orig["description"])
    expect(recv["placement_type"]).to eql(orig["placement_type"])
    expect(recv["category"]).to eql(orig["category"])
  end

  def verify_action_content(orig, recv)
    expect(recv["id"]).to   eql(orig["id"])
    expect(recv["name"]).to eql(orig["name"])
    expect(recv["source_type"]).to eql(orig["source_type"])
  end


  context 'Get all placements' do
    context 'with valid app id' do

      xit 'should return one placement with no action' do
        p = create_placement(app_id: app_id)
        code, placements = Placement.get(app_id: app_id)

        expect(code).to eql(200)
        expect(placements.count).to eql(1)
        verify_placement_content(p, placements[0])
        expect(placements[0]["actions"].count).to eql(0)
      end

      xit 'should return one placement with one action' do
        p = create_placement(app_id:app_id)
        a = create_action(AdAction, app_id: app_id,
                          currency_id: app_id,
                          placement_ids: [p["id"]])

        code, placements = Placement.get(app_id: app_id)

        expect(code).to eql(200)
        expect(placements.count).to eql(1)
        verify_placement_content(p, placements[0])
        expect(placements[0]["actions"].count).to eql(1)
        verify_action_content(a, placements[0]["actions"][0])
      end

      xit 'should return one placement with multiple actions' do
        p =  create_placement(app_id:app_id)
        a1 = create_action(AdAction, app_id:app_id,
                           currency_id: app_id,
                           placement_ids: [p["id"]])
        a2 = create_action(AdAction, app_id:app_id,
                           currency_id: app_id,
                           placement_ids: [p["id"]])

        code, placements = Placement.get(app_id: app_id)

        expect(code).to eql(200)
        expect(placements.count).to eql(1)
        verify_placement_content(p, placements[0])
        expect(placements[0]["actions"].count).to eql(2)
        verify_action_content(a1, placements[0]["actions"][0])
        verify_action_content(a2, placements[0]["actions"][1])
      end

      xit 'should return 2 placements with one action each' do
        p1 = create_placement(app_id: app_id)
        p2 = create_placement(app_id: app_id)
        a  = create_action(AdAction, app_id: app_id,
                           currency_id: app_id,
                           placement_ids: [p1["id"], p2["id"]])

        code, placements = Placement.get(app_id: app_id)

        expect(code).to eql(200)
        expect(placements.count).to eql(2)
        expect(placements[0]["actions"].count).to eql(1)
        expect(placements[1]["actions"].count).to eql(1)

        placements.each do | pmt |
          if pmt["id"] == p1["id"]
            verify_placement_content(p1, pmt)
            verify_action_content(a, pmt["actions"][0])
          else
            verify_placement_content(p2, pmt)
            verify_action_content(a, pmt["actions"][0])
          end
        end
      end
    end

    context 'with invalid app id' do
      xit 'should have no placements' do
        create_placement(app_id: app_id)
        code, placements = Placement.get(app_id: invalid_app_id)
        expect(code).to eql(200)
        expect(placements.count).to eql(0)
      end
    end
  end

  context 'Get specific placement' do
    context 'with valid placement' do
      xit 'should return placement' do
        p = create_placement(app_id: app_id)
        code, placement = Placement.get(app_id: app_id, placement_id:p["id"])

        expect(code).to eql(200)
        verify_placement_content(p, placement)
        expect(placement["actions"].count).to eql(0)
      end

      xit 'should return no placement if app id is non-existent' do
        p = create_placement(app_id: app_id)
        expect { Placement.get(app_id: invalid_app_id,
                               placement_id:p["id"])
               }.to raise_error(Faraday::ResourceNotFound)
      end
    end

    context 'with non-existent placement' do
      xit 'should return no placement' do
        create_placement(app_id: app_id)
        expect { Placement.get(app_id: app_id,
                               placement_id: invalid_placement_id)
               }.to raise_error(Faraday::ResourceNotFound)
      end

      xit 'should return no placement if app id is non-existent' do
        create_placement(app_id: app_id)
        expect { Placement.get(app_id: invalid_app_id ,
                               placement_id: invalid_placement_id)
               }.to raise_error(Faraday::ResourceNotFound)
      end
    end
  end

  context 'Create placement' do
    context 'with valid params' do
      let(:valid_name) { 'valid_name' }
      let(:valid_desc) { 'valid_desc' }
      let(:default_category) { 'user_pause' }
      let(:contextual) { 'contextual' }
      let(:user_initiated) { 'user_initiated' }
      let(:user_pause) { 'user_pause' }
      let(:achievement) { 'achievement' }
      let(:failure) { 'faiure' }
      let(:app_launch) { 'app_launch' }

      xit 'should create placement with name, desc, category and type' do
        p = create_placement(name: valid_name,
                             description: valid_desc,
                             category: default_category,
                             placement_type: contextual,
                             app_id: app_id
                            )

        code, placement = Placement.get(app_id: app_id, placement_id: p["id"])

        expect(code).to eql(200)
        expect(placement["name"]).to eql(valid_name)
        expect(placement["description"]).to eql(valid_desc)
        expect(placement["category"]).to eql(default_category)
        expect(placement["placement_type"]).to eql(contextual)
      end

      xit 'should create placement with type user initiated' do
        p = create_placement(name: valid_name,
                             description: valid_desc,
                             category: user_pause,
                             placement_type: user_initiated,
                             app_id: app_id
                            )

        code, placement = Placement.get(app_id: app_id, placement_id: p["id"])


        expect(code).to eql(200)
        expect(placement["name"]).to eql(valid_name)
        expect(placement["description"]).to eql(valid_desc)
        expect(placement["category"]).to eql(user_pause)
        expect(placement["placement_type"]).to eql(user_initiated)
      end

      xit 'should create placement with category achievement' do
        p = create_placement(name: valid_name,
                             description: valid_desc,
                             category: achievement,
                             placement_type: contextual,
                             app_id: app_id
                            )
        code, placement = Placement.get(app_id: app_id, placement_id: p["id"])

        expect(code).to eql(200)
        expect(placement["name"]).to eql(valid_name)
        expect(placement["description"]).to eql(valid_desc)
        expect(placement["category"]).to eql(achievement)
        expect(placement["placement_type"]).to eql(contextual)
      end

      xit 'should create placement with category failure' do
        p = create_placement(name: valid_name,
                             description: valid_desc,
                             category: failure,
                             placement_type: contextual,
                             app_id: app_id
                            )
        code, placement = Placement.get(app_id: app_id, placement_id: p["id"])


        expect(code).to eql(200)
        expect(placement["name"]).to eql(valid_name)
        expect(placement["description"]).to eql(valid_desc)
        expect(placement["category"]).to eql(failure)
        expect(placement["placement_type"]).to eql(contextual)
      end

      xit 'should create placement with category app launch' do
        p = create_placement(name: valid_name,
                             description: valid_desc,
                             category: app_launch,
                             placement_type: contextual,
                             app_id: app_id
                            )
        code, placement = Placement.get(app_id: app_id, placement_id: p["id"])

        expect(code).to eql(200)
        expect(placement["name"]).to eql(valid_name)
        expect(placement["description"]).to eql(valid_desc)
        expect(placement["category"]).to eql(app_launch)
        expect(placement["placement_type"]).to eql(contextual)

      end

      xit 'should create placement with no category' do
        p = create_placement(name: valid_name,
                             description: valid_desc,
                             placement_type: contextual,
                             app_id: app_id
                            )
        code, placement = Placement.get(app_id: app_id, placement_id: p["id"])

        expect(code).to eql(200)
        expect(placement["name"]).to eql(valid_name)
        expect(placement["description"]).to eql(valid_desc)
        expect(placement["category"]).to eql(user_pause)
        expect(placement["placement_type"]).to eql(contextual)
      end

      xit 'should create placement with no description' do
        p = create_placement(name: valid_name,
                             category: user_pause,
                             placement_type: contextual,
                             app_id: app_id
                            )
        code, placement = Placement.get(app_id: app_id, placement_id: p["id"])

        expect(code).to eql(200)
        expect(placement["name"]).to eql(valid_name)
        expect(placement["category"]).to eql(user_pause)
        expect(placement["placement_type"]).to eql(contextual)
      end

      xit 'should create placement with no placement_type' do
        p = create_placement(name: valid_name, app_id: app_id)
        code, placement = Placement.get(app_id: app_id, placement_id: p["id"])

        expect(code).to eql(200)
        expect(placement["name"]).to eql(valid_name)
        expect(placement["category"]).to eql(user_pause)
        expect(placement["placement_type"]).to eql(contextual)
      end
    end

    context 'with invalid params' do
      def verify_payload(payload)
         expect { Placement.post(payload) }.to raise_error(Faraday::ClientError)
      end

      xit 'without name' do
         payload = Placement.new(app_id: app_id).payload.except(:name)
         verify_payload(payload)
      end

      xit 'with blank name' do
         payload = Placement.new(app_id: app_id, name: '').payload.except(:name)
         verify_payload(payload)
      end

      xit 'with two placements with the same name' do
        create_placement(name: 'same_name', app_id: app_id)
        payload = Placement.new(app_id: app_id, name: 'same_name').payload.except(:name)
        verify_payload(payload)
      end

      xit 'invalid placement_type' do
        payload = Placement.new(app_id: app_id, placement_type: 'bad_one').payload.except(:name)
        verify_payload(payload)
      end
    end
  end

  context 'Delete placement', focus: true do
    context 'valid placement' do
      xit 'should delete placement' do
        p = create_placement(app_id: app_id)
        Placement.delete(app_id: app_id, placement_id: p["id"])
        expect { Placement.get(app_id: app_id,
                               placement_id: p["id"])
               }.to raise_error(Faraday::ResourceNotFound)
      end

      xit 'should not delete placement if app_id does not match' do
        p = create_placement(app_id: app_id)
        expect { Placement.delete(app_id: invalid_app_id,
                                  placement_id: p["id"])
               }.to raise_error(Faraday::ResourceNotFound)
      end
    end

    context 'non existent placement' do
      xit 'should not find placement' do
        expect { Placement.delete(app_id: app_id,
                                  placement_id: invalid_placement_id)
               }.to raise_error(Faraday::ResourceNotFound)
      end
    end
  end

  context 'Update placement' do
    context 'valid placement' do
      xit 'should update placement with valid param' do
        p = create_placement(app_id: app_id)
        code, placement = Placement.put( app_id: app_id,
                                   placement_id: p["id"],
                                   name: 'new_name'
                                 )

        expect(code).to eql(200)
        expect(placement["name"]).to eql('new_name')
      end

      xit 'should not update placement if app id does not match' do
        p = create_placement(app_id: app_id)
        expect { Placement.put(app_id: invalid_app_id,
                              placement_id: p["id"],
                              name:"new_name")
               }.to raise_error(Faraday::ResourceNotFound)
      end
    end

    context 'non existent placement' do
      xit 'should fail' do
        create_placement(app_id: app_id)
        expect { Placement.put(app_id: app_id,
                              placement_id: invalid_placement_id,
                              name:"new_name")
               }.to raise_error(Faraday::ResourceNotFound)
      end
    end
  end
end
