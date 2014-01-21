require 'spec_helper'

describe BoxFixer do
  let(:box) { create :box }

  before do
    expect(box).to receive(:push_box_updated_message)
  end

  describe '.fix' do
    it 'tries to restart the box when it stucked in starting' do
      box.state = "starting"
      expect(box.coach).to receive(:restart_box)
      BoxFixer.fix box
      expect(box).to be_restarting
    end

    it 'tries to stop the box when it stucked in stopping' do
      box.state = "stopping"
      expect(box.coach).to receive(:stop_box)
      BoxFixer.fix box
      expect(box).to be_stopping
    end

    it 'tries to restart the box when it stucked in restarting' do
      box.state = "restarting"
      expect(box.coach).to receive(:restart_box)
      BoxFixer.fix box
      expect(box).to be_restarting
    end

    it 'tries to terminate the box when it stucked in terminating' do
      box.state = "terminating"
      expect(box.coach).to receive(:terminate_box)
      BoxFixer.fix box
      expect(box).to be_terminating
    end
  end
end
