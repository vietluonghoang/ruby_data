require 'spec_helper'

module ActionDecoratorHelper
  def create_offer(offer_class, create_action, edit_action)
    settings_hash = { create_with: create_action, edit_with: edit_action }

    settings_hash.merge!(app_id: app.id)  if app_required?(offer_class)
    settings_hash.merge!(item_id: app.id) if item_required?(offer_class)

    offer_class.new(settings_hash)
  end

  def all_offer_decorators
    valid_offer_decorators = []

    TestChamber::Offer.descendants.each do |offer_class|
      action_combinations.each do |create_action, edit_action|
        decorator = [offer_class, create_action, edit_action]

        valid_offer_decorators << decorator if valid_decorator?(*decorator)
      end
    end

    valid_offer_decorators
  end

  def collect_attribs(offer) # returns a 2d array [[attr, value], [attr, value] ...]
    instance_vars = offer.instance_variables.collect do |iv|
      next if [:@edit_api_body, :@create_api_response].include?(iv)
      [ivar_to_sym(iv), offer.instance_variable_get(iv)]
    end

    instance_vars.compact
  end

  private

  def app
    @app ||= TestChamber::App.new
  end

  def action_combinations
    actions = TestChamber::ActionDecorator.actions
    actions.product(actions)
  end

  def valid_decorator?(offer_class, create_action, edit_action)
    offer_type = offer_class.to_s.demodulize
    creator = "TestChamber::Creator::#{offer_type}::#{create_action.to_s.camelcase}"
    editor = "TestChamber::Editor::#{offer_type}::#{edit_action.to_s.camelcase}"

    Object.const_defined?(creator) && Object.const_defined?(editor) &&
      offer_class != TestChamber::Offer::Survey
  end

  def app_required?(offer_class)
    app_required = [
      TestChamber::Offer::Action,
      TestChamber::Offer::Engagement,
      TestChamber::Offer::Reconnect
    ].include?(offer_class)
  end

  def item_required?(offer_class)
    item_required = [
      TestChamber::Offer::Engagement,
      TestChamber::Offer::Reconnect
    ].include?(offer_class)
  end

  def ivar_to_sym(ivar)
    ivar.to_s[1..-1].to_sym
  end

  def sym_to_ivar(sym)
    ('@' + sym.to_s).to_sym
  end
end


RSpec::Matchers.define :be_updated_with do |edit_attributes|
  updates = nil
  match do |offer|

    original_attribs = collect_attribs(offer) # returns a 2d array [attr, value]
    offer.edit(edit_attributes)               # call edit on offer
    new_attribs = collect_attribs(offer)      # returns a 2d array [attr, value]

    updated_attributes = Hash[new_attribs]    # transform 2d array of updated attrs into hash
    updates = original_attribs - new_attribs  # returns 2d array of all updated attrs [attr, value]

    updates.all? { |attr, _| edit_attributes[attr] == updated_attributes[attr] }
  end

  failure_message_for_should do |offer|
    "expected #{Hash[updates]} to equal #{edit_attributes}"
  end
end


describe "Offer create/edit pattern" do
  include ActionDecoratorHelper # access #all_offer_decorators & #create_offer within 'it' blocks.
  extend ActionDecoratorHelper  # access #all_offer_decorators within this 'describe' block.

  # shared @app used in ActionDecoratorHelper#create_offer.
  before(:all) do
    @app = TestChamber::App.new
  end

  it "has one or more examples" do
    expect(all_offer_decorators).not_to be_empty
  end

  all_offer_decorators.each do |offer_class, create_action, edit_action|
    context "validates #{offer_class} decorator" do
      let(:offer) { create_offer(offer_class, create_action, edit_action) }
      let(:edit_attributes) { { name: 'edited name', title: 'edited title', details: 'edited details' } }

      # edit requires a created offer to edit; separate examples duplicate tests and produce misleading failures.
      it "can create using #{create_action} and edit using #{edit_action}" do
        if offer_class.eql?(TestChamber::Offer::Video) && create_action != :api
          expect { offer }.to raise_error
        else
          expect(offer).to be_valid
          expect(offer).to be_updated_with(edit_attributes)
        end
      end
    end
  end
end
