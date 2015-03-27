require 'spec_helper'

describe TestChamber::Offer::Video, :type => :feature do
  it_validates "signed up by a reseller at 60% revshare"
end
