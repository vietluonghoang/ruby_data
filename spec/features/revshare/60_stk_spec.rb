require 'spec_helper'

describe TestChamber::Offer::Generic, :type => :feature do
  it_validates "revshare at 60% and store is skt"
end

describe TestChamber::Offer::Mraid, :type => :feature do
  it_validates "revshare at 60% and store is skt"
end

describe TestChamber::Offer::Video, :type => :feature do
  it_validates "revshare at 60% and store is skt"
end
