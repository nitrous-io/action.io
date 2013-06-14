describe FetchBoxInfoJob do
  describe "#perform" do
    let!(:user)       { create :user }
    let!(:box)        { create :box, owner: user }
    let!(:mock_coach) { double :coach }

    before do
      Box.any_instance.stub(:coach).and_return mock_coach
      mock_coach.stub!(:fetch_box_info).and_return true
    end

    it "should call Coach#fetch_box_info" do
      mock_coach.should_receive(:fetch_box_info).and_return(true)

      FetchBoxInfoJob.new(box.id, user.id).perform
    end
  end
end
