RSpec::Matchers.define :be_a_uuid do
  match do |actual_id|
    TestChamber::UUID.uuid?(actual_id)
  end

  failure_message do |actual|
    "Expected UUID, got \"#{actual}\" instead"
  end
end
