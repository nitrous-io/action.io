class Repository < ActiveRecord::Base
  belongs_to :box, inverse_of: :repositories

  attr_accessible :name, :full_name, :clone_url

  module SCM
    # Enum. In Rails 4.1.0, you can do `enum scm: %w(git mercurial unsupported)`.
    TYPES = [
      UNSUPPORTED = 'unsupported',
      GIT = 'git',
      MERCURIAL = 'mercurial'
    ]
  end

  validates_presence_of :clone_url
  validates :scm, inclusion: { in: SCM::TYPES, message: '%{value} is not a valid SCM type' }

  state_machine initial: :queued do
    event(:initiate_identify)        { transition :queued => :identifying }
    event(:identified)               { transition :identifying => :identified }
    event(:initiate_clone)           { transition :identified => :cloning }
    event(:cloned)                   { transition :cloning => :cloned }
    event(:failed)                   { transition :cloning => :failed }

    before_transition(on: :initiate_clone)    { |repo| repo.pre_initiate_clone }

    after_transition(on: :initiate_identify)  { |repo| IdentifyRepositoryJob.submit_job(repo) }
    after_transition(on: :cloned) do |repo|
      repo.update_attribute :cloned_at, Time.now
      repo.user.clear_intent!
    end
    after_transition do: :push_repository_updated_message
  end

  scope :uncloned, -> { where('state <> ?', 'cloned') }

  # FIXME Do we need these?
  # attr_accessor :html_url # URL to repo's webpage.
  # attr_accessor :ssh_url  # Needed for cloning private repos that users can push to.

  def clone_url=(val)
    self[:clone_url] = val.try(:shellescape)
  end

  def user
    self.box.owner
  end

  def coach
    self.box.coach
  end

  def pre_initiate_clone
    box.update_attribute(:touched_at, Time.now) if box && !box.new_record?
    self.coach.clone_repo(self)
  end

  def push_repository_updated_message
    Shover.publish self.user.id, 'aio:repository_updated', self.serialize_as_hash
  end

  def github?
    !!(clone_url =~ %r{github.com})
  end

  def bitbucket?
    !!(clone_url =~ %r{bitbucket.org})
  end
end
