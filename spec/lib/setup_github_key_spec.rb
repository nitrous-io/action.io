require 'spec_helper'

describe SetupGithubKey do
  describe ".setup" do
    let(:ssh_key) { stub(ssh_public_key: "public_key", private_key: "private_key") }
    let(:github_user) { stub(add_key: true) }
    let(:box) { create :box }

    context "when the box owner has authenticated with github" do
      before do
        GithubUser.should_receive(:init).with(box.owner) { github_user }
      end

      it 'add public key to github' do
        ReadDefaultPublicKey.should_receive(:run).with(box) { "public_key" }
        box_name = "actionio-#{box.name}"
        github_user.should_receive(:add_key).with(box_name, "public_key")
        described_class.setup box
      end

      it 'does not add the public key when we cant read the default public key' do
        ReadDefaultPublicKey.should_receive(:run).with(box) { nil }
        github_user.should_not_receive(:add_key)
        described_class.setup box
      end
    end

    context "when the box owner hasnt authenticated with github" do
      before do
        GithubUser.should_receive(:init).with(box.owner) { GithubUser::NON_AUTHENTICATED_USER }
      end

      it 'does not do anything' do
        github_user.should_not_receive(:add_key)
        described_class.setup box
      end
    end
  end
end
