require 'spec_helper'

describe Addon do
  it_behaves_like 'a model that has an encrypted attribute', Addon, :password
  it_behaves_like 'a model that has an encrypted attribute', Addon, :sso_salt

  it { should_not allow_mass_assignment_of :uid}
  it { should_not allow_mass_assignment_of :config_vars }
  it { should_not allow_mass_assignment_of :required_vars }
  it { should_not allow_mass_assignment_of :production_base_url }
  it { should_not allow_mass_assignment_of :production_sso_url }
  it { should_not allow_mass_assignment_of :test_base_url }
  it { should_not allow_mass_assignment_of :test_sso_url }
  it { should_not allow_mass_assignment_of :encrypted_password }
  it { should_not allow_mass_assignment_of :encrypted_password_iv }
  it { should_not allow_mass_assignment_of :encrypted_sso_salt }
  it { should_not allow_mass_assignment_of :encrypted_sso_salt_iv }
  it { should_not allow_mass_assignment_of :state }
  it { should_not allow_mass_assignment_of :description }

  it { should belong_to(:owner).class_name('User')     }
  it { should have_many(:addon_admins)                 }
  it { should have_many(:users).through(:addon_admins) }

  describe 'validations' do
    let!(:addon) { create :addon }

    it { should validate_presence_of :uid}
    it { should validate_presence_of :config_vars }
    it { should validate_presence_of :production_base_url }
    it { should validate_presence_of :production_sso_url }
    it { should validate_presence_of :test_base_url }
    it { should validate_presence_of :test_sso_url }
    it { should validate_presence_of :encrypted_password }
    it { should validate_presence_of :encrypted_password_iv }
    it { should validate_presence_of :encrypted_sso_salt }
    it { should validate_presence_of :encrypted_sso_salt_iv }
    it { should validate_presence_of :state }

    it { should validate_uniqueness_of :production_base_url }
    it { should validate_uniqueness_of :production_sso_url }
    it { should validate_uniqueness_of :test_base_url }
    it { should validate_uniqueness_of :test_sso_url }
    it { should validate_uniqueness_of :uid }

    it 'validates presence of owner only when addon is a new record' do
       addon.owner = nil
       addon.should be_valid
       new_addon = build :addon, owner: nil
       new_addon.should_not be_valid
    end
  end

  context 'before create' do
    it 'adds owner to users' do
      user = create :user
      addon = create :addon, owner: user
      addon.users.should == [user]
    end
  end

  describe ".parse_manifest" do
    context "invalid manifest JSON" do
      before do
        @addon = Addon.parse_manifest('a')
      end

      it "should have errors set on the payload attribute" do
        @addon.errors[:payload].should == ["cannot be parsed"]
      end
    end

    context "valid JSON with not all properties filled in" do
      before do
        @addon = Addon.parse_manifest('{"id":"my_addon"}')
      end

      it "should have errors set" do
        @addon.should_not be_valid
      end
    end

    context "valid JSON with all properties filled in" do
      let!(:valid_manifest_json) do
<<eos
{
  "id": "action_rds_addon",
  "api": {
    "config_vars": [ "AMAZON_RDS_URL", "AMAZON_RDS_USERNAME", "AMAZON_RDS_PASSWORD", "AMAZON_RDS_HOST", "AMAZON_RDS_PORT" ],
    "required_vars": { "amazon_rds_url": "Your Amazon RDS URL (e.g. mysql://user:pass@rdshostname.amazonaws.com)" },
    "password": "dummy_password",
    "sso_salt": "dummy_sso_salt",
    "production": {
      "base_url": "https://rds.action.io/aio/resources",
      "sso_url": "https://rds.action.io/sso/login"
    },
    "test": {
      "base_url": "http://localhost:5000/aio/resources",
      "sso_url": "http://localhost:5000/sso/login"
    }
  }
}
eos
      end

      before { @addon = Addon.parse_manifest(valid_manifest_json) }

      it "should have all the attributes filled in" do
        @addon.uid.should == 'action_rds_addon'
        @addon.password.should == 'dummy_password'
        @addon.sso_salt.should == 'dummy_sso_salt'
        @addon.production_base_url.should == 'https://rds.action.io/aio/resources'
        @addon.production_sso_url.should == 'https://rds.action.io/sso/login'
        @addon.test_base_url.should == 'http://localhost:5000/aio/resources'
        @addon.test_sso_url.should == 'http://localhost:5000/sso/login'

        @addon.config_vars.should == ["AMAZON_RDS_URL", "AMAZON_RDS_USERNAME", "AMAZON_RDS_PASSWORD", "AMAZON_RDS_HOST", "AMAZON_RDS_PORT"]
        @addon.required_vars.should == { "amazon_rds_url" => "Your Amazon RDS URL (e.g. mysql://user:pass@rdshostname.amazonaws.com)" }
      end

    end
  end
end
