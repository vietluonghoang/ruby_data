require 'spec_helper'

describe TestChamber::Offer::Video, :type => :feature do
  it_validates "max deductions at 70% revshare"
end
