require 'spec_helper'

describe TestChamber::Offer::Video, type: :feature do
  it_validates "revshare at 50% with no offer discount"
  it_validates "revshare at 50% with 10% offer discount"
  it_validates "revshare at 50% with 15% offer discount"
end
