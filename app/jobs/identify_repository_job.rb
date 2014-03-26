require 'timeout'

# This job requires Git and Mercurial to be available to the server workers are
# running on.  As of time of writing, workers run on Heroku dynos, which will already have git.  Mercurial install process as follows:
#
# See http://spin.atomicobject.com/2012/12/09/building-and-deploying-custom-binaries-on-heroku/ for more verbose overview.  NOTE: Vulcan is deprecated, so ignore references to it
#
# 1. `heroku create action-build-hg`
# 2. `heroku run bash -a action-build-hg`
# In the heroku bash session:
# 3. `curl --silent --max-time 60 --location http://mercurial.selenic.com/release/mercurial-2.9.1.tar.gz | tar xz`
# 4. cd mercurial-2.9.1
# 5. `PYTHONPATH=/app/vendor/mercurial/lib/python2.7/site-packages:${PYTHONPATH} && make install-bin PREFIX=/app/vendor/mercurial`
# 6. `cd /app`
# 7. `tar zcf mercurial-2.9.1.tar.gz vendor`  Be sure that the only directory in vendor is "mercurial", or use -C option for tar accordingly.  The tar needs to have vendor/mercurial path 
# 8. scp the mercurial-2.9.1.tar.gz somewhere you have s3cmd, then `s3cmd -P put mercurial-2.9.1.tar.gz s3://assets.action.io`
# 9. the public url of the s3 file needs to be in this repository REPO_ROOT/.vendor_urls
# 10. REPO_ROOT/.buildpacks needs to have https://github.com/peterkeen/heroku-buildpack-vendorbinaries.git # TODO use our own buildpack and make it more flexible
# 11. `heroku config:set PATH=vendor/mercurial/bin:EXISTING_PATH -a production-app` (replace EXISTING_PATH with the value from config:get

# IdentifyRepositoryJob takes a repository and optional user id.
# If given a saved repository, it determines the scm and updates the repository in the database
# If given a new repository, user id is required.  The job determines the scm and
# publishes the repository to Shover.
class IdentifyRepositoryJob < Job
  attr_accessor :repository, :user_id

  TIMEOUT = 30 # seconds

  def initialize(repository, user_id=nil)
    raise "Expected a valid repository" if !repository.is_a?(Repository) || !repository.valid?
    raise "Expected a repository in identifying state" if repository.state != 'identifying'

    self.repository = repository

    if repository.new_record?
      raise "Valid user_id is required" if User.find_by_id(user_id).nil?
      self.user_id = user_id
    else
      raise "Valid box_id is required" if !repository.box.is_a?(Box)
      self.user_id = repository.box.owner_id
    end
  end

  def perform
    self.repository.scm = identify_scm
    if self.repository.new_record?
      self.repository.state = 'identified'
      Shover.publish self.user_id, 'aio:repository_identified', self.repository.serialize_as_hash[:repository]
    else
      self.repository.identified!
      # for saved repositories, the aio:repository_updated message will fire on state change so aio:repository_identified is not necessary
    end
  end

  def self.submit_job(repository, user_id=nil)
    Delayed::Job.enqueue(new(repository, user_id))
  end

  def identify_scm
    # the sequence of checks should be by scm popularity (most->least)
    return Repository::SCM::GIT if is_git?
    return Repository::SCM::MERCURIAL if is_mercurial?
    Repository::SCM::UNSUPPORTED
  end

  def is_git?
    spawn_with_timeout("git ls-remote #{clone_url} >/dev/null 2>&1") == :success
  end

  def is_mercurial?
    spawn_with_timeout("hg identify #{clone_url} >/dev/null 2>&1") == :success
  end

  def clone_url
    repository.clone_url.shellescape
  end

  def self.timeout
    TIMEOUT
  end

  private

  # spawn_with_timeout runs given command with a timeout and returns one of
  # :success, :fail, :timed_out
  def spawn_with_timeout(command)
    pid = Process.spawn(command)
    begin
      Timeout::timeout(self.class.timeout) do # 30 seconds
        Process.wait(pid)
        $?.exitstatus == 0 ? :success : :fail
      end
    rescue Timeout::Error
      Process.kill("TERM", pid)
      :timeout
    end
  end
end
