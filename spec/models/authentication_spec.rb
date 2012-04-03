require 'spec_helper'

describe Authentication do
  it { should have_db_column(:user_id).of_type(:integer).with_options(null: false) }
  it { should have_db_column(:provider).of_type(:string).with_options(null: false) }
  it { should have_db_column(:uid).of_type(:string).with_options(null: false) }

  it { should have_db_column(:created_at).of_type(:datetime) }
  it { should have_db_column(:updated_at).of_type(:datetime) }

  it { should have_db_index(:user_id) }
  it { should have_db_index([:provider, :uid]) }

  it { should_not allow_mass_assignment_of :user_id }
  it { should_not allow_mass_assignment_of :provider }
  it { should_not allow_mass_assignment_of :uid }
  it { should_not allow_mass_assignment_of :created_at }
  it { should_not allow_mass_assignment_of :updated_at }

  it { should belong_to :user }

  describe 'validations' do
    before { create(:authentication).should be_valid }

    it { should validate_presence_of :provider }
    it { should validate_presence_of :uid }
  end
end
