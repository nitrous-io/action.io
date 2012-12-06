require 'spec_helper'

describe Document do
  it { should allow_mass_assignment_of(:path) }
  it { should allow_mass_assignment_of(:content) }
  it { should allow_mass_assignment_of(:dirty) }
  it { should belong_to(:box).dependent(:destroy) }
  it { should belong_to(:user).dependent(:destroy) }

  describe 'validation' do
    let!(:document) { create :document }
    it { should validate_uniqueness_of(:path).scoped_to(:user_id, :box_id).with_message('should not contain duplicated document') }
    it { should validate_presence_of(:path) }
  end
end
