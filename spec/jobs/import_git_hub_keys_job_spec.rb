require 'spec_helper'

describe ImportGitHubKeysJob do
  describe '.perform' do
    let!(:user) { create :user_with_invite }
    before { User.stub!(:find).with(user.id) { user } }
    let!(:job)  { ImportGitHubKeysJob.new(user.id) }

    it 'calls .import_github_keys on PublicKey model with the user as the argument' do
      PublicKey.should_receive(:import_github_keys).with(user)
      job.perform
    end
  end
end
