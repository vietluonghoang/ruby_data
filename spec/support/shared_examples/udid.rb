shared_examples "it has a UUID" do
  it "has a UUID" do
    test_id.should be_a_uuid
  end
end