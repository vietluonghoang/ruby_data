require 'spec_helper'

describe TestChamber::Statz do
  include_context "I am logged in"

  let(:statz) { TestChamber::Statz.new }

  it "should get some statz" do
    expect(statz.global_statz).not_to be_nil
  end
end
