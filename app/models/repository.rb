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

  validates_presence_of :clone_url, :download_branch
  validates :scm, inclusion: { in: SCM::TYPES, message: '%{value} is not a valid SCM type' }

  state_machine initial: :queued do
    event(:initiate_identify)        { transition :queued                   => :identified }
    event(:initiate_clone)           { transition :identified               => :cloning     }
    event(:cloned)                   { transition :cloning                  => :cloned      }
    # The failure message can sometimes come back too quickly from the backend
    # before the transition has had time to take place (noticed on staging)
    # so allow transition from :identified to :failed
    event(:failed)                   { transition [:cloning, :identified]   => :failed      }

    before_transition(on: :initiate_clone)    { |repo| repo.pre_initiate_clone }

    after_transition(on: :cloned) do |repo|
      repo.update_attribute :cloned_at, Time.now
    end
    after_transition do: :push_repository_updated_message
  end

  def clone_url=(val)
    self[:clone_url] = val.try(:shellescape)
  end

  def archive_url
    if clone_url =~ /.git$/
      clone_url.sub(/.git$/, "/archive/#{download_branch}.tar.gz")
    else
      "#{clone_url}/archive/#{download_branch}.tar.gz"
    end
  end

  def user
    self.box.owner
  end

  def coach
    self.box.coach
  end

  def pre_initiate_clone
    box.update_attribute(:touched_at, Time.now) if box && !box.new_record?
    self.coach.download_repo_archive(self)
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
