require 'spec_helper'

describe Document do
  it { should allow_mass_assignment_of(:pathname) }
  it { should allow_mass_assignment_of(:content) }
  it { should allow_mass_assignment_of(:last_saved_content) }
  it { should belong_to(:box) }
  it { should belong_to(:user) }

  describe 'validation' do
    let!(:document) { create :document }
    it { should validate_uniqueness_of(:pathname).scoped_to(:user_id, :box_id).with_message('should not contain duplicated document') }
    it { should validate_presence_of(:pathname) }
  end
end
