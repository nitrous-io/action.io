class Repository < ActiveRecord::Base
  belongs_to :box, inverse_of: :repositories

  attr_accessible :name, :full_name, :clone_url

  validates_presence_of :clone_url

  module SCM
    # Enum. In Rails 4.1.0, you can do `enum scm: %i( git mercurial unsupported )`.
    UNSUPPORTED = 0
    GIT = 1
    MERCURIAL = 2
  end

  state_machine initial: :queued do
    event(:initiate_clone)  { transition :queued => :cloning }
    event(:cloned)          { transition :cloning => :cloned }
    event(:failed)          { transition :cloning => :failed }

    before_transition(on: :initiate_clone) { |repo| repo.pre_initiate_clone }
    after_transition(on: :cloned) { |repo| repo.update_attribute :cloned_at, Time.now }
    after_transition do: :push_repository_updated_message
  end

  scope :uncloned, -> { where('state <> ?', 'cloned') }

  # FIXME Should the repository model detect the SCM type of a repo, or leave
  # that to the caller? Or be agnostic and let goboxer do the detection?
  # Benefit of knowing the SCM: we can show e.g. a "Git" menu item in the IDE.

  # FIXME Do we need these?
  # attr_accessor :html_url # URL to repo's webpage.
  # attr_accessor :ssh_url  # Needed for cloning private repos that users can push to.

  def user
    self.box.owner
  end

  def coach
    self.box.coach
  end

  def scm=(value)
    # Basically an enum "enforcer".
    scm = case value
    when SCM::GIT, SCM::MERCURIAL
      value
    else
      SCM::UNSUPPORTED
    end
    write_attribute :scm, scm
  end

  def pre_initiate_clone
    self.coach.clone_repo(clone_url)
    self.user.clear_intent
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
