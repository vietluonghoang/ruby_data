require 'spec_helper'

describe TestChamber::Offer::Generic, :type => :feature do
  it_validates "revshare at 70% with no offer discount"
  it_validates "revshare at 70% with 10% offer discount"
  it_validates "revshare at 70% with 15% offer discount"
  it_validates "revshare at 70% with 30% offer discount"
end
