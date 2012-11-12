require 'spec_helper'

describe SetupGithubKey do
  describe ".setup" do
    let(:ssh_key) { stub(ssh_public_key: "public_key", private_key: "private_key") }
    let(:github_user) { stub(add_key: true) }
    let(:box) { create :box }

    context "when the box owner has authenticated with github" do
      before do
        GithubUser.should_receive(:init).with(box.owner) { github_user }
        box.stub(:add_github_private_key)
      end

      it 'add public key to github' do
        box_name = "actionio-#{box.name}"
        github_user.should_receive(:add_key).with(box_name, "public_key")
        described_class.setup box, ssh_key
      end

      it 'sends private key to the box' do
        box.should_receive(:add_github_private_key).with("private_key")
        described_class.setup box, ssh_key
      end
    end

    context "when the box owner hasnt authenticated with github" do
      before do
        GithubUser.should_receive(:init).with(box.owner) { GithubUser::NON_AUTHENTICATED_USER }
      end

      it 'does not do anything' do
        github_user.should_not_receive(:add_key)
        box.should_not_receive(:add_github_private_key)
        described_class.setup box, ssh_key
      end
    end
  end
end
