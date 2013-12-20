require 'spec_helper'

describe SetupGithubKey do
  describe '.setup' do
    let(:github_user) { instance_double('GithubUser', add_key: true) }
    let(:box) { create :box }
    let(:channel) { instance_double('Pusher::Channel') }

    before do
      Pusher.stub(:[]).with("private-user-#{box.owner.id}") { channel }
      channel.stub(:trigger)
      Shover.stub(:publish)
    end

    context 'when the box owner has authenticated with github' do
      before do
        GithubUser.stub(:new).with(box.owner) { github_user }
        github_user.stub(:authenticated?) { true }
      end

      context 'when public key is found' do
        before { expect(ReadDefaultPublicKey).to receive(:run).with(box) { 'some_fancy_public_key' } }

        it 'adds public key to github' do
          box_name = "nitrousio-#{box.name}"
          expect(github_user).to receive(:add_key).with(box_name, 'some_fancy_public_key')
          described_class.setup box
        end

        it 'sends a pusher notification stating that the key was successfully added' do
          expect(Shover).to receive(:publish).with(box.owner.id, 'aio:add_public_key_to_github', {
            box: { id: box.id },
            status: 'ok'
          })

          expect(channel).to receive(:trigger) do |message, data|
            expect(message).to eq 'aio:add_public_key_to_github'
            expect(data).to eq({
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
            expect(Shover).to receive(:publish).with(box.owner.id, 'aio:add_public_key_to_github', {
              box: { id: box.id },
              status: 'fail',
              error: 'github_validation_failed'
            })

            expect(channel).to receive(:trigger) do |message, data|
              expect(message).to eq 'aio:add_public_key_to_github'
              expect(data).to eq({
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
          expect(ReadDefaultPublicKey).to receive(:run).with(box) { nil }
        end

        it 'does not add the public key' do
          expect(github_user).not_to receive(:add_key)
          described_class.setup box
        end

        it 'sends a pusher notification stating that pub key was not found' do
          expect(Shover).to receive(:publish).with(box.owner.id, 'aio:add_public_key_to_github', {
            box: { id: box.id },
            status: 'fail',
            error: 'public_key_not_found'
          })

          expect(channel).to receive(:trigger) do |message, data|
            expect(message).to eq 'aio:add_public_key_to_github'
            expect(data).to eq({
              box: { id: box.id },
              status: 'fail',
              error: 'public_key_not_found'
            }.to_json)
          end
          described_class.setup box
        end
      end
    end

    context 'when the box owner has not authenticated with github' do
      before do
        expect(GithubUser).to receive(:new).with(box.owner) { github_user }
        github_user.stub(:authenticated?) { false }
      end

      it 'does not do anything' do
        expect(github_user).not_to receive(:add_key)
        described_class.setup box
      end
    end

    context 'when there is some other error' do
      before do
        GithubUser.stub(:new).and_raise 'SomeError'
      end

      it 'sends a pusher notification with the error' do
        expect(Shover).to receive(:publish).with(box.owner.id, 'aio:add_public_key_to_github', {
          box: { id: box.id },
          status: 'fail',
          error: 'SomeError'
        })

        expect(channel).to receive(:trigger) do |message, data|
          expect(message).to eq 'aio:add_public_key_to_github'
          expect(data).to eq({
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
