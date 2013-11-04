require 'spec_helper'

describe SetupGithubKey do
  describe ".setup" do
    let(:ssh_key) { stub(ssh_public_key: "public_key", private_key: "private_key") }
    let(:github_user) { stub(add_key: true) }
    let(:box) { create :box }
    let(:channel) { double.as_null_object }

    before do
      Pusher.stub(:[]).with("private-user-#{box.owner.id}") { channel }
      channel.stub(:trigger)
    end

    context "when the box owner has authenticated with github" do
      before do
        GithubUser.should_receive(:init).with(box.owner) { github_user }
      end

      context 'when public key is found' do
        before { ReadDefaultPublicKey.should_receive(:run).with(box) { "some_fancy_public_key" } }

        it 'adds public key to github' do
          box_name = "nitrousio-#{box.name}"
          github_user.should_receive(:add_key).with(box_name, "some_fancy_public_key")
          described_class.setup box
        end

        it 'sends a pusher notification stating that the key was successfully added' do
          channel.should_receive(:trigger) do |message, data|
            message.should eq 'aio:add_public_key_to_github'
            data.should eq({
              box: { id: box.id },
              status: 'ok'
            }.to_json)
          end
          described_class.setup box
        end

        context 'when public key already exists in github' do
          before do
            github_user.stub(:add_key).and_raise Octokit::UnprocessableEntity
          end

          it 'sends a pusher notification stating that the key was not added' do
            channel.should_receive(:trigger) do |message, data|
              message.should eq 'aio:add_public_key_to_github'
              data.should eq({
                box: { id: box.id },
                status: 'fail',
                error: 'github_validation_failed'
              }.to_json)
            end
            described_class.setup box
          end
        end
      end

      context 'when public key does not exist' do
        before do
          ReadDefaultPublicKey.should_receive(:run).with(box) { nil }
        end

        it 'does not add the public key' do
          github_user.should_not_receive(:add_key)
          described_class.setup box
        end

        it 'sends a pusher notification stating that pub key was not found' do
          channel.should_receive(:trigger) do |message, data|
            message.should eq 'aio:add_public_key_to_github'
            data.should == {
              box: { id: box.id },
              status: 'fail',
              error: 'public_key_not_found'
            }.to_json
          end
          described_class.setup box
        end
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

    context 'when there is some other error' do
      before do
        GithubUser.stub(:init).and_raise 'SomeError'
      end

      it 'sends a pusher notification with the error' do
        channel.should_receive(:trigger) do |message, data|
          message.should eq 'aio:add_public_key_to_github'
          data.should eq({
            box: { id: box.id },
            status: 'fail',
            error: 'SomeError'
          }.to_json)
        end
        described_class.setup box
      end
    end
  end
end
