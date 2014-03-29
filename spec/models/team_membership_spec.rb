require 'spec_helper'

describe TeamMembership do
  describe 'Associations' do
    it { should belong_to :team }
    it { should belong_to(:member).class_name('User') }
  end

  describe 'Validations' do
    it { should validate_presence_of :member_id }
    it { should validate_presence_of :team_id   }
  end
end
