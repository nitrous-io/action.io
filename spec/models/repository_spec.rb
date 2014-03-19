require 'spec_helper'

describe Repository do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :full_name }
  it { should allow_mass_assignment_of :clone_url }
  it { should_not allow_mass_assignment_of :box_id }
  it { should_not allow_mass_assignment_of :state }
  it { should_not allow_mass_assignment_of :scm }
  it { should_not allow_mass_assignment_of :private }
  it { should_not allow_mass_assignment_of :cloned_at }

  it { should belong_to(:box) }

  describe 'validations' do
    it { should validate_presence_of(:clone_url) }
  end

  describe 'state machine' do
    let!(:repository) { create :repository }

    it 'should have an initial state of queued' do
      expect(repository.state).to eql 'queued'
    end

    describe '#initiate_clone' do
      it 'initiates cloning of the repository and changes state to cloning' do
        expect(repository).to receive(:pre_initiate_clone)

        expect {
          repository.initiate_clone!
        }.to change { repository.state }.from('queued').to('cloning')
      end
    end

    describe '#cloned' do
      before do
        repository.update_attribute :state, 'cloning'
        Timecop.freeze
        @now = Time.now
      end

      after { Timecop.return }

      it 'changes state to cloned' do
        expect {
          repository.cloned!
        }.to change { repository.state }.from('cloning').to('cloned')
      end

      it 'sets the cloned_at property to now' do
        repository.cloned!
        expect(repository.cloned_at).to eql @now
      end
    end

    describe '#failed' do
      before { repository.update_attribute :state, 'cloning' }

      it 'changes state to failed' do
        expect {
          repository.failed!
        }.to change { repository.state }.from('cloning').to('failed')
      end
    end
  end

  describe 'scopes' do
    let(:repository_1) { create :repository, state: 'queued' }
    let(:repository_2) { create :repository, state: 'cloning' }
    let(:repository_3) { create :repository, state: 'cloned' }
    let(:repository_4) { create :repository, state: 'failed' }

    describe '.uncloned' do
      it 'returns all repositories that are not yet cloned' do
        expect(Repository.uncloned).to match_array [repository_1, repository_2, repository_4]
      end
    end
  end

  describe '#user' do
    let(:owner) { create :user }
    let(:box) { create :box, owner: owner }
    let(:repository) { create :repository, box: box }

    it "returns the box's owner" do
      expect(repository.user).to eql owner
    end
  end

  describe '#coach' do
    let(:box) { create :box }
    let(:repository) { create :repository, box: box }
    let(:coach) { instance_double('Coach') }

    before { allow(box).to receive(:coach).and_return(coach) }

    it "returns its box's Coach instance" do
      expect(repository.coach).to eql coach
    end
  end

  describe '#scm=' do
    let(:repository) { create :repository }

    context 'when an unrecognized type is set' do
      before { repository.scm = 'darcs' }

      it 'should set the SCM to unsupported' do
        expect(repository.scm).to eql Repository::SCM::UNSUPPORTED
      end
    end

    context 'when a recognized type is set' do
      before { repository.scm = Repository::SCM::GIT }

      it 'should set the SCM to the given type' do
        expect(repository.scm).to eql Repository::SCM::GIT
      end
    end
  end

  describe '#pre_initiate_clone' do
    let(:user) { create :user }
    let(:repository) { create :repository, clone_url: 'https://github.com/rails/rails.git' }
    let(:coach) { instance_double('Coach') }

    before do
      allow(repository).to receive(:coach).and_return(coach)
      allow(coach).to receive(:clone_repo)
      allow(repository).to receive(:user).and_return(user)
    end

    it 'calls Coach to clone the repo' do
      expect(coach).to receive(:clone_repo).with('https://github.com/rails/rails.git')
      repository.pre_initiate_clone
    end

    it "clears the user's intent" do
      expect(user).to receive(:clear_intent!)
      repository.pre_initiate_clone
    end
  end

  describe '#push_repository_updated_message' do
    let(:repository) { create :repository }

    it 'pushes an aio:repository_updated message to its user' do
      expect(Shover).to receive(:publish).with(repository.user.id, 'aio:repository_updated', repository.serialize_as_hash)
      repository.push_repository_updated_message
    end
  end

  describe '#github?' do
    let(:repository) { create :repository }

    context 'when clone URL includes "github.com"' do
      before { repository.clone_url = 'https://github.com/nitrous-io/autoparts.git' }

      it 'returns true' do
        expect(repository.github?).to eql true
      end
    end

    context 'when clone URL does not include "github.com"' do
      before { repository.clone_url = 'https://pornhub.com/nitrous-io/private-parts.gif' }

      it 'returns false' do
        expect(repository.github?).to eql false
      end
    end
  end

  describe '#bitbucket?' do
    let(:repository) { create :repository }

    context 'when clone URL includes "github.com"' do
      before { repository.clone_url = 'https://nitrous-io@bitbucket.org/nitrous-io/autoparts' }

      it 'returns true' do
        expect(repository.bitbucket?).to eql true
      end
    end

    context 'when clone URL does not include "github.com"' do
      before { repository.clone_url = 'https://github.com/nitrous-io/autoparts.git' }

      it 'returns false' do
        expect(repository.bitbucket?).to eql false
      end
    end
  end
end
