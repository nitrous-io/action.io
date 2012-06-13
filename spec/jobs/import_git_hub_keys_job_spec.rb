require 'spec_helper'

describe ImportGitHubKeysJob do
  subject { ImportGitHubKeysJob }

  it 'is on external_api_jobs queue' do
    subject.instance_variable_get(:@queue).should == :external_api_jobs
  end

  describe '.perform' do
    let!(:user) { create :user_with_invite }
    before { User.stub!(:find).with(user.id) { user } }

    it 'calls .import_github_keys on PublicKey model with the user as the argument' do
      PublicKey.should_receive(:import_github_keys).with(user)
      subject.perform(user.id)
    end
  end
end
