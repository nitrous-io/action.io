require 'spec_helper'

describe Boxhost do
  it { should allow_mass_assignment_of :name }
  it { should_not allow_mass_assignment_of :ip }
  it { should_not allow_mass_assignment_of :state }
  it { should_not allow_mass_assignment_of :dedicated }
  it { should_not allow_mass_assignment_of :terminated_at }
  it { should_not allow_mass_assignment_of :owner_id }
  it { should_not allow_mass_assignment_of :location_id }
  it { should_not allow_mass_assignment_of :boxhost_plan_id }
  it { should_not allow_mass_assignment_of :boxhost_provider_template_id }

  it { should belong_to(:owner).class_name('User') }
  it { should belong_to(:location) }
  it { should belong_to(:boxhost_plan) }
  it { should belong_to(:boxhost_provider_template) }

  it { should have_many(:key_pairs).dependent(:destroy) }

  describe 'validations' do
    let!(:boxhost) { create :boxhost }

    it { should validate_presence_of(:name) }
    it { should ensure_length_of(:name).is_at_least(4).is_at_most(40) }

    describe 'location' do
      let!(:location) { create :location }

      context 'when creating a new location record' do
        context 'when location is present' do
          let!(:new_boxhost) { build :boxhost, location: location }

          it 'should be valid' do
            expect(new_boxhost).to be_valid
          end
        end

        context 'when location is absent' do
          let!(:new_boxhost) { build :boxhost, location: nil }

          it 'should be valid' do
            expect(new_boxhost).to be_valid
          end
        end
      end

      context 'when box is unprovisioned' do
        before { boxhost.update_column(:state, 'born') }

        context 'when location is present' do
          before { boxhost.location = location }

          it 'should be valid' do
            expect(boxhost).to be_valid
          end
        end

        context 'when location is absent' do
          before { boxhost.location = nil }

          it 'should not be valid' do
            expect(boxhost).not_to be_valid
            expect(boxhost.error_on(:location_id).size).to eq 1
          end
        end
      end

      context 'when box is already provisioned' do
        before { boxhost.update_column(:state, 'running') }

        context 'when location is changed' do
          before do
            expect(boxhost.location).not_to eql location
            boxhost.location = location
          end

          it 'should not be valid' do
            expect(boxhost).not_to be_valid
            expect(boxhost.error_on(:location_id).size).to eq 1
            expect(boxhost.error_on(:location_id).first).to eq 'Location can no longer be changed.'
          end
        end

        context 'when location is unchanged' do
          it 'should be valid' do
            expect(boxhost).to be_valid
          end
        end
      end
    end
  end

  describe 'state machine' do
    let!(:boxhost) { create :boxhost }

    describe '#enqueue_provision' do
      before { boxhost.update_attribute :state, 'born' }

      it 'changes the state to provisioning' do
        expect {
          boxhost.enqueue_provision!
        }.to change(boxhost, :state).from('born').to('provisioning')
      end

      it 'creates a key pair for the boxhost' do
        expect(boxhost).to receive(:generate_key_pair)
        boxhost.enqueue_provision
      end
    end

    describe '#enqueue_start' do
      context 'when the initial state is provisioning' do
        before { boxhost.update_attribute :state, 'provisioning' }

        it 'changes the state to starting' do
          expect {
            boxhost.enqueue_start!
          }.to change(boxhost, :state).from('provisioning').to('starting')
        end
      end

      context 'when the initial state is stopped' do
        before { boxhost.update_attribute :state, 'stopped' }

        it 'changes the state to starting' do
          expect {
            boxhost.enqueue_start!
          }.to change(boxhost, :state).from('stopped').to('starting')
        end
      end
    end

    describe '#start' do
      before { boxhost.update_attribute :state, 'starting' }

      it 'starts the boxhost' do
        expect {
          boxhost.start!
        }.to change(boxhost, :state).from('starting').to('running')
      end
    end

    describe '#enqueue_stop' do
      before { boxhost.update_attribute :state, 'running' }

      it 'changes the state to stopping' do
        expect {
          boxhost.enqueue_stop!
        }.to change(boxhost, :state).from('running').to('stopping')
      end
    end

    describe '#stop' do
      before { boxhost.update_attribute :state, 'stopping' }

      it 'stops the boxhost' do
        expect {
          boxhost.stop!
        }.to change(boxhost, :state).from('stopping').to('stopped')
      end
    end

    describe '#enqueue_restart' do
      before { boxhost.update_attribute :state, 'running' }

      it 'changes the state to restarting' do
        expect {
          boxhost.enqueue_restart!
        }.to change(boxhost, :state).from('running').to('restarting')
      end
    end

    describe '#restart' do
      before { boxhost.update_attribute :state, 'restarting' }

      it 'restarts the boxhost' do
        expect {
          boxhost.restart!
        }.to change(boxhost, :state).from('restarting').to('running')
      end
    end

    describe '#enqueue_terminate' do
      before { boxhost.update_attribute :state, 'stopped' }

      it 'changes the state to terminating' do
        expect {
          boxhost.enqueue_terminate!
        }.to change(boxhost, :state).from('stopped').to('terminating')
      end
    end

    describe '#terminate' do
      before { boxhost.update_attribute :state, 'terminating' }

      it 'terminates the boxhost' do
        expect {
          boxhost.terminate!
        }.to change(boxhost, :state).from('terminating').to('terminated')
      end

      it 'updates the termination time of the boxhost' do
        Timecop.freeze 5.hours.from_now do
          expect {
            boxhost.terminate!
          }.to change { boxhost.terminated_at.to_i }.to(Time.now.to_i)
        end
      end
    end
  end

  describe '#generate_name' do
    let!(:boxhost) { create :boxhost }

    context 'when boxhost is not associated to a boxhost plan' do
      before { boxhost.update_attribute :boxhost_plan, nil }

      it 'returns "boxes"' do
        expect(boxhost.generate_name).to eq 'boxes'
      end
    end

    context 'when boxhost is associated to a boxhost plan' do
      let!(:boxhost_plan) { create :boxhost_plan, name: 'Super Awesome Boxes' }
      before { boxhost.update_attribute :boxhost_plan, boxhost_plan }

      it 'returns "boxes-" appended with the boxhost plan name' do
        expect(boxhost.generate_name).to eq 'boxes-Super Awesome Boxes'
      end
    end
  end

  describe '#generate_key_pair' do
    let!(:boxhost) { create :boxhost }
    let!(:mock_key) { double('ssh_key', private_key: 'some-private-key', ssh_public_key: 'some-public-key') }

    it 'generates and adds a key pair to the boxhost' do
      expect(GenerateSSHKey).to receive(:generate) { mock_key }

      expect {
        @key_pair = boxhost.generate_key_pair
      }.to change(boxhost.key_pairs, :count).by(1)

      expect(@key_pair.private_key).to eq('some-private-key')
      expect(@key_pair.public_key).to eq('some-public-key')
    end
  end

  describe '#public_keys' do
    let!(:boxhost) { create :boxhost }

    context 'when boxhost has no key pairs' do
      it 'returns an empty array' do
        expect(boxhost.public_keys).to eq []
      end
    end

    context 'when boxhost has (generated) key pairs' do
      let!(:generated_key_pair) { create :key_pair, ssh_identifiable: boxhost, public_key: 'pub', private_key: 'priv' }

      it 'returns the generated public keys' do
        expect(boxhost.public_keys).to eq ['pub']
      end
    end
  end
end
