require 'spec_helper'

describe TestChamber::Offer::Generic, :type => :feature do
  it_validates "publisher equals advertiser at 60% revshare with 15% offer discount"
end

describe TestChamber::Offer::Mraid, :type => :feature do
  it_validates "publisher equals advertiser at 60% revshare with 15% offer discount"
end

describe TestChamber::Offer::Video, :type => :feature do
  it_validates "publisher equals advertiser at 60% revshare with 15% offer discount"
end
