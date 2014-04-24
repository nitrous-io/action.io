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
  it { should_not allow_mass_assignment_of :download_branch }

  it { should belong_to(:box) }

  describe 'validations' do
    it { should validate_presence_of(:clone_url) }
    it { should validate_presence_of(:download_branch) }
    it { should ensure_inclusion_of(:scm).in_array(Repository::SCM::TYPES) }
  end

  describe 'state machine' do
    let!(:repository) { create :repository }

    it 'should have an initial state of queued' do
      expect(repository.state).to eql 'queued'
    end

    describe '#initiate_clone' do
      it 'initiates cloning of the repository and changes state to cloning' do
        repository.update_column(:state, 'identified')
        expect(repository).to receive(:pre_initiate_clone)

        expect {
          repository.initiate_clone!
        }.to change { repository.state }.from('identified').to('cloning')
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

  describe '#clone_url=' do
    let(:repository) { build :repository }

    it 'leaves regular urls alone' do
      url = 'https://github.com/nitrous-io/autoparts.git'
      repository.clone_url = url
      expect(repository.clone_url).to eq url
    end

    it 'escapes ||' do
      repository.clone_url = "norepo || touch ohnoes"
      expect(repository.clone_url).to include('\\ \\|\\|')
    end

    it 'escapes backticks' do
      repository.clone_url = "https://github.com/`touch ohnoes`"
      expect(repository.clone_url).to include('\\`')
    end
  end

  describe '#archive_url' do
    let(:repository) { build :repository }

    context 'when clone URL ends in ".git"' do
      before { repository.clone_url = 'https://github.com/nitrous-io/autoparts.git' }

      it 'returns the path to a tarball of the master branch of the repository' do
        expect(repository.archive_url).to eq 'https://github.com/nitrous-io/autoparts/archive/master.tar.gz'
      end
    end

    context 'when clone URL contains a period' do
      before { repository.clone_url = 'https://github.com/nitrous-io/autoparts.js.git' }

      it 'returns the path to a tarball of the master branch of the repository' do
        expect(repository.archive_url).to eq 'https://github.com/nitrous-io/autoparts.js/archive/master.tar.gz'
      end
    end

    context 'when clone URL does not end in ".git"' do
      before { repository.clone_url = 'https://github.com/nitrous-io/autoparts' }

      it 'returns the path to a tarball of the master branch of the repository' do
        expect(repository.archive_url).to eq 'https://github.com/nitrous-io/autoparts/archive/master.tar.gz'
      end
    end

    context 'when default branch is "gh-pages"' do
      before do
        repository.clone_url = 'https://github.com/nitrous-io/autoparts'
        repository.download_branch = 'gh-pages'
      end

      it 'returns the path to a tarball of the gh-pages branch of the repository' do
        expect(repository.archive_url).to eq 'https://github.com/nitrous-io/autoparts/archive/gh-pages.tar.gz'
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

  describe '#pre_initiate_clone' do
    let(:user) { create :user }
    let(:repository) { create :repository, clone_url: 'https://github.com/rails/rails.git' }
    let(:coach) { instance_double('Coach') }

    before do
      allow(repository).to receive(:coach).and_return(coach)
      allow(coach).to receive(:download_repo_archive)
      allow(repository).to receive(:user).and_return(user)
    end

    it 'calls Coach to clone the repo' do
      expect(coach).to receive(:download_repo_archive).with(repository)
      repository.pre_initiate_clone
    end

    context 'when a saved box is present' do
      it 'updates the box touched_at so it does not get shutdown in the middle of a clone' do
        Timecop.freeze(Time.now) do
          expect(repository.box).to receive(:update_attribute).with(:touched_at, Time.now)
          repository.pre_initiate_clone
        end
      end
    end

    context 'when a saved box is absent' do
      it 'does not attempt to update box touched_at' do
        repository.box = nil
        expect(repository.box).not_to receive(:update_attribute)
        repository.pre_initiate_clone
      end
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
      before { repository.clone_url = 'https://bitbucket.org/nitrous-io/autoparts.git' }

      it 'returns false' do
        expect(repository.github?).to eql false
      end
    end
  end

  describe '#bitbucket?' do
    let(:repository) { create :repository }

    context 'when clone URL includes "bitbucket.org"' do
      before { repository.clone_url = 'https://nitrous-io@bitbucket.org/nitrous-io/autoparts' }

      it 'returns true' do
        expect(repository.bitbucket?).to eql true
      end
    end

    context 'when clone URL does not include "bitbucket.org"' do
      before { repository.clone_url = 'https://github.com/nitrous-io/autoparts.git' }

      it 'returns false' do
        expect(repository.bitbucket?).to eql false
      end
    end
  end
end
