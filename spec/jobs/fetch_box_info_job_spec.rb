describe FetchBoxInfoJob do
  describe "#perform" do
    let!(:user)       { create :user }
    let!(:box)        { create :box, owner: user }
    let!(:mock_coach) { double :coach }

    before do
      allow_any_instance_of(Box).to receive(:coach).and_return mock_coach

      mock_coach.stub(:fetch_box_info).and_return true
    end

    it "should call Coach#fetch_box_info" do
      expect(mock_coach).to receive(:fetch_box_info).and_return(true)

      FetchBoxInfoJob.new(box.id, user.id).perform
    end
  end
end
