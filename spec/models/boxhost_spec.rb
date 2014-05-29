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

    it { should allow_value('super-secrud-project-69').for(:name) }
    it { should allow_value('supersecrudproject69').for(:name) }
    it { should_not allow_value('sup3r-s3cr@d-pr0j3ct-69').for(:name) }
    it { should_not allow_value('super_secrud_project_69').for(:name) }
    it { should_not allow_value('69-super-secrud-project').for(:name) }
    it { should_not allow_value('-super-secrud-project-69').for(:name) }
    it { should_not allow_value('super-secrud-project-69-').for(:name) }
    it { should_not allow_value('super secrud project 69').for(:name) }
    it { should_not allow_value('秘密おっぱい').for(:name) }
    it { should_not allow_value('秘密-おっぱい-69').for(:name) }

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
    let!(:location) { create :location }
    let!(:boxhost_plan) { create :boxhost_plan }
    let!(:boxhost_provider_template) { create :boxhost_provider_template, location: location, boxhost_plan: boxhost_plan }

    before do
      allow(boxhost).to receive :push_boxhost_updated_message
      allow_any_instance_of(BoxhostProviderTemplate).to receive(:supported?).and_return(true)
    end

    describe '#enqueue_provision' do
      before do
        boxhost.state = 'born'
        boxhost.location = location
        boxhost.boxhost_plan = boxhost_plan
        boxhost.save!

        allow(boxhost).to receive(:provision_with_hostbuilder).and_return(true)
      end

      context 'when valid' do
        context 'when the initial state is born' do
          it 'changes the state to provisioning' do
            expect(boxhost).to receive :push_boxhost_updated_message
            expect {
              boxhost.enqueue_provision!
            }.to change(boxhost, :state).from('born').to('provisioning')
          end
        end

        context 'when the initial state is failed' do
          before { boxhost.update_column :state, 'failed' }

          it 'changes the state to provisioning' do
            expect(boxhost).to receive :push_boxhost_updated_message
            expect {
              boxhost.enqueue_provision!
            }.to change(boxhost, :state).from('failed').to('provisioning')
          end
        end

        it 'creates a key pair for the boxhost' do
          expect(boxhost).to receive(:generate_key_pair)
          boxhost.enqueue_provision!
        end

        it 'provisions with hostbuilder' do
          expect(boxhost).to receive(:provision_with_hostbuilder).and_return(true)
          boxhost.enqueue_provision!
        end

        context 'when provisioning with with hostbuilder fails' do
          it 'halts the transition' do
            expect(boxhost).to receive(:provision_with_hostbuilder).and_return(false)
            expect {
              boxhost.enqueue_provision!
            }.to raise_error StateMachine::InvalidTransition
          end
        end
      end

      context 'validations for provisioning state' do
        before { boxhost.update_column :state, 'provisioning' }

        context 'when location_id is absent' do
          before do
            boxhost.update_column :location_id, nil
          end

          it 'should be invalid' do
            expect(boxhost).not_to be_valid
          end

          context 'when transitioning to the provisioning state' do
            before { boxhost.update_column :state, 'born' }

            it 'raises a StateMachine::InvalidTransition error' do
              expect {
                boxhost.enqueue_provision!
              }.to raise_error(StateMachine::InvalidTransition, /Location can't be blank/)
            end
          end
        end

        context 'when boxhost_plan_id is absent' do
          before do
            boxhost.update_column :boxhost_plan_id, nil
          end

          it 'should be invalid' do
            expect(boxhost).not_to be_valid
          end

          context 'when transitioning to the provisioning state' do
            before { boxhost.update_column :state, 'born' }

            it 'raises a StateMachine::InvalidTransition error' do
              expect {
                boxhost.enqueue_provision!
              }.to raise_error(StateMachine::InvalidTransition, /Boxhost plan can't be blank/)
            end
          end
        end

        context 'when there is no available boxhost provider template' do
          before do
            boxhost_provider_template.update_column :location_id, nil
          end

          it 'should be invalid' do
            expect(boxhost).not_to be_valid
          end

          context 'when transitioning to the provisioning state' do
            before { boxhost.update_column :state, 'born' }

            it 'raises a StateMachine::InvalidTransition error' do
              expect {
                boxhost.enqueue_provision!
              }.to raise_error(StateMachine::InvalidTransition, /location is not currently available/)
            end
          end
        end
      end
    end

    describe '#orphan' do
      before do
        boxhost.update_column :state, 'provisioning'
        boxhost.update_column :location_id, location.id
        boxhost.update_column :boxhost_plan_id, boxhost_plan.id
      end

      it 'changes the state to failed' do
        expect(boxhost).to receive :push_boxhost_updated_message
        expect {
          boxhost.orphan!
        }.to change(boxhost, :state).from('provisioning').to('failed')
      end
    end

    describe '#enqueue_start' do
      context 'when the initial state is provisioning' do
        before { boxhost.update_attribute :state, 'provisioning' }

        it 'changes the state to starting' do
          expect(boxhost).to receive :push_boxhost_updated_message
          expect {
            boxhost.enqueue_start!
          }.to change(boxhost, :state).from('provisioning').to('starting')
        end
      end

      context 'when the initial state is stopped' do
        before { boxhost.update_attribute :state, 'stopped' }

        it 'changes the state to starting' do
          expect(boxhost).to receive :push_boxhost_updated_message
          expect {
            boxhost.enqueue_start!
          }.to change(boxhost, :state).from('stopped').to('starting')
        end
      end
    end

    describe '#start' do
      before { boxhost.update_attribute :state, 'starting' }

      it 'starts the boxhost' do
        expect(boxhost).to receive :push_boxhost_updated_message
        expect {
          boxhost.start!
        }.to change(boxhost, :state).from('starting').to('running')
      end
    end

    describe '#enqueue_stop' do
      before { boxhost.update_attribute :state, 'running' }

      it 'changes the state to stopping' do
        expect(boxhost).to receive :push_boxhost_updated_message
        expect {
          boxhost.enqueue_stop!
        }.to change(boxhost, :state).from('running').to('stopping')
      end
    end

    describe '#stop' do
      before { boxhost.update_attribute :state, 'stopping' }

      it 'stops the boxhost' do
        expect(boxhost).to receive :push_boxhost_updated_message
        expect {
          boxhost.stop!
        }.to change(boxhost, :state).from('stopping').to('stopped')
      end
    end

    describe '#enqueue_restart' do
      before { boxhost.update_attribute :state, 'running' }

      it 'changes the state to restarting' do
        expect(boxhost).to receive :push_boxhost_updated_message
        expect {
          boxhost.enqueue_restart!
        }.to change(boxhost, :state).from('running').to('restarting')
      end
    end

    describe '#restart' do
      before { boxhost.update_attribute :state, 'restarting' }

      it 'restarts the boxhost' do
        expect(boxhost).to receive :push_boxhost_updated_message
        expect {
          boxhost.restart!
        }.to change(boxhost, :state).from('restarting').to('running')
      end
    end

    describe '#enqueue_terminate' do
      before { boxhost.update_attribute :state, 'stopped' }

      it 'changes the state to terminating' do
        expect(boxhost).to receive :push_boxhost_updated_message
        expect {
          boxhost.enqueue_terminate!
        }.to change(boxhost, :state).from('stopped').to('terminating')
      end
    end

    describe '#terminate' do
      before { boxhost.update_attribute :state, 'terminating' }

      it 'terminates the boxhost' do
        expect(boxhost).to receive :push_boxhost_updated_message
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

  describe '#unprovisioned?' do
    let!(:boxhost) { create :boxhost }

    context 'when boxhost is in the born state' do
      before { boxhost.state = 'born' }

      it 'returns true' do
        expect(boxhost.unprovisioned?).to eq true
      end
    end

    context 'when boxhost is in the failed state' do
      before { boxhost.state = 'failed' }

      it 'returns true' do
        expect(boxhost.unprovisioned?).to eq true
      end
    end

    %w(provisioning starting running stopping stopped
       restarting running terminating terminated).each do |state|
      context "when boxhost is in the #{state} state" do
        before { boxhost.state = state }
        it 'returns false' do
          expect(boxhost.unprovisioned?).to eq false
        end
      end
    end
  end

  describe '#hostbuilder' do
    context 'when boxhost does not have a boxhost provider template' do
      let!(:boxhost) { create :boxhost }

      it 'returns nil' do
        expect(boxhost.hostbuilder).to be_nil
      end
    end

    context 'when boxhost has a boxhost provider template' do
      let!(:boxhost_provider_template) { create :boxhost_provider_template }
      let!(:boxhost) { create :boxhost, boxhost_provider_template: boxhost_provider_template }

      context 'when boxhost provider template does not have a Hostbuilder class' do
        before do
          expect(boxhost_provider_template).to receive(:hostbuilder_class).and_return(nil)
        end

        it 'returns nil' do
          expect(boxhost.hostbuilder).to be_nil
        end
      end

      context 'when boxhost provider template has a Hostbuilder class' do
        before do
          class Hostbuilder::Fake < Hostbuilder::Base; end
          expect(boxhost_provider_template).to receive(:hostbuilder_class).and_return(Hostbuilder::Fake)
        end

        it 'returns a hostbuilder instance with the boxhost attribute set to the boxhost' do
          hostbuilder = boxhost.hostbuilder
          expect(hostbuilder).to be_kind_of Hostbuilder::Base
          expect(hostbuilder.boxhost).to eq boxhost
        end
      end
    end
  end

  describe '#provision_with_hostbuilder' do
    context 'when there is no template available to be picked' do
      let!(:boxhost) { create :boxhost }
      before { expect(boxhost).to receive(:pick_template).and_return(nil) }

      it 'returns false' do
        expect(boxhost.provision_with_hostbuilder).to eq false
      end
    end

    context 'when there is a template available to be picked' do
      class Hostbuilder::SupportedProvider < Hostbuilder::Base
        attr_accessor :create_called

        def create
          self.create_called = true
        end
      end

      let!(:location) { create :location }
      let!(:boxhost_plan) { create :boxhost_plan }

      let!(:boxhost_provider_template) { create :boxhost_provider_template, location: location, boxhost_plan: boxhost_plan, provider: 'supported_provider' }

      let!(:boxhost) { create :boxhost, location: location, boxhost_plan: boxhost_plan }

      before do
        expect(boxhost).to receive(:pick_template).and_return(boxhost_provider_template)
      end

      context 'when boxhost cannot be saved' do
        before do
          boxhost.location = boxhost.boxhost_plan = nil
          expect(boxhost).not_to be_valid
        end

        it 'returns false' do
          expect(boxhost.provision_with_hostbuilder).to eq false
        end

        it 'does not call create on its hostbuilder' do
          boxhost.provision_with_hostbuilder
          expect(boxhost.hostbuilder.create_called).not_to eq true
        end
      end

      context 'when boxhost can be saved' do
        it 'sets its boxhost provider template to the picked template' do
          boxhost.provision_with_hostbuilder
          expect(boxhost.reload.boxhost_provider_template).to eq boxhost_provider_template
        end

        it 'calls create on the hostbuilder' do
          boxhost.provision_with_hostbuilder
          expect(boxhost.hostbuilder.create_called).to eq true
        end
      end
    end
  end

  describe '#available_templates' do
    context 'when there are no boxhost provider templates with the same location and boxhost plan' do
      let!(:boxhost) { create :boxhost }

      it 'returns an empty array' do
        expect(boxhost.available_templates).to be_empty
      end
    end

    context 'when there are boxhost provider templates with the same location and boxhost plan' do
      class Hostbuilder::SupportedProvider < Hostbuilder::Base; end

      let!(:location1) { create :location }
      let!(:location2) { create :location }
      let!(:boxhost_plan1) { create :boxhost_plan }
      let!(:boxhost_plan2) { create :boxhost_plan }

      let!(:boxhost_provider_template1) { create :boxhost_provider_template, location: location1, boxhost_plan: boxhost_plan1, provider: 'supported_provider' }
      let!(:boxhost_provider_template2) { create :boxhost_provider_template, location: location1, boxhost_plan: boxhost_plan1, provider: 'unsupported' }
      let!(:boxhost_provider_template3) { create :boxhost_provider_template, location: location1, boxhost_plan: boxhost_plan1, provider: 'supported_provider' }
      let!(:boxhost_provider_template4) { create :boxhost_provider_template, location: location1, boxhost_plan: boxhost_plan2, provider: 'supported_provider' }
      let!(:boxhost_provider_template5) { create :boxhost_provider_template, location: location2, boxhost_plan: boxhost_plan1, provider: 'supported_provider' }
      let!(:boxhost_provider_template6) { create :boxhost_provider_template, location: location2, boxhost_plan: boxhost_plan2, provider: 'supported_provider' }

      let!(:boxhost) { create :boxhost, location: location1, boxhost_plan: boxhost_plan1 }

      it 'returns only the templates with the same location and boxhost plan that are supported' do
        expect(boxhost.available_templates).to match_array [boxhost_provider_template1, boxhost_provider_template3]
      end
    end
  end

  describe '#pick_template' do
    let!(:boxhost) { create :boxhost }

    context 'when there are no available templates' do
      it 'returns nil' do
        expect(boxhost.pick_template).to be_nil
      end
    end

    context 'when there are available templates' do
      let!(:boxhost_provider_template1) { create :boxhost_provider_template }
      let!(:boxhost_provider_template2) { create :boxhost_provider_template }

      before do
        allow(boxhost).to receive(:available_templates).and_return([boxhost_provider_template1, boxhost_provider_template2])
      end

      it 'returns one of the available templates' do
        expect(boxhost.pick_template).not_to be_nil
        expect(boxhost.available_templates).to include boxhost.pick_template
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

  describe '#push_boxhost_updated_message' do
    let(:user) { create :user }
    let!(:boxhost) { create :boxhost, owner: user }

    it 'pushes a aio:boxhost_updated message to its owner' do
      expect(Shover).to receive(:publish).with(
        user.id,
        'aio:boxhost_updated',
        boxhost.serialize_as_hash
      )
      boxhost.push_boxhost_updated_message
    end
  end
end
