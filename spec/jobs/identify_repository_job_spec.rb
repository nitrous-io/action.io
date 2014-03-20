require 'spec_helper'

describe IdentifyRepositoryJob do
  let!(:repository) { create :repository, clone_url: 'file:///tmp' }
  let!(:job) { IdentifyRepositoryJob.new(repository) }

  def fake_repo(scm_cmd, basedir)
    repo_dir = basedir + [scm_cmd, SecureRandom.urlsafe_base64].join('-')
    commands = [
      "mkdir #{repo_dir}",
      "cd #{repo_dir} && #{scm_cmd} init",
      "cd #{repo_dir} && touch .#{scm_cmd}ignore",
      "cd #{repo_dir} && #{scm_cmd} add .#{scm_cmd}ignore",
      "cd #{repo_dir} && #{scm_cmd} commit #{scm_cmd == 'hg' ? "--config 'ui.username=test'" : ''} -m 'Initial Commit' ",
    ]
    commands.each do |command|
      output = `#{command}`
      next if $?.success?
      raise "Command `#{command}` failed with exit status #{$?.exitstatus}, output #{output}"
    end
    repo_dir
  end

  def fake_git(basedir)
    fake_repo('git', basedir)
  end

  def fake_mercurial(basedir)
    fake_repo('hg', basedir)
  end

  before do
    @tmpdir = Pathname.new(Dir.mktmpdir("identify_repository_job_spec"))
  end

  after do
    FileUtils.remove_entry_secure(@tmpdir)
  end

  describe '#initialize' do
    it 'requires a valid repository' do
      expect { IdentifyRepositoryJob.new('not a repo') }.to raise_error
      expect { IdentifyRepositoryJob.new(Repository.new) }.to raise_error
    end
  end

  describe '#perform' do
    it 'saves identified scm' do
      job.stub(:identify_scm).and_return(Repository::SCM::GIT)
      job.perform
      expect(repository.reload.scm).to eq Repository::SCM::GIT
    end
  end

  describe '#identify_scm' do
    it 'checks git' do
      job.stub(:is_git?).and_return(true)
      expect(job.identify_scm).to eq Repository::SCM::GIT
    end

    it 'checks mercurial' do
      job.stub(:is_git?).and_return(false)
      job.stub(:is_mercurial?).and_return(true)
      expect(job.identify_scm).to eq Repository::SCM::MERCURIAL
    end

    it 'defaults to unsupported' do
      job.stub(:is_git?).and_return(false)
      job.stub(:is_mercurial?).and_return(false)
      expect(job.identify_scm).to eq Repository::SCM::UNSUPPORTED
    end
  end

  describe '#is_git?' do
    it 'identifies a git repository' do
      dir = fake_git(@tmpdir)
      repository.clone_url = "file://#{dir}"
      expect(job.is_git?).to eq true
    end

    it 'is false on timeout' do
      IdentifyRepositoryJob.stub(:timeout).and_return(0.0001)
      dir = fake_git(@tmpdir)
      repository.clone_url = "file://#{dir}"
      expect(job.is_git?).to eq false
    end

    it 'is false on mercurial repository' do
      dir = fake_mercurial(@tmpdir)
      repository.clone_url = "file://#{dir}"
      expect(job.is_git?).to eq false
    end
  end

  describe '#is_mercurial?' do
    it 'identifies a mercurial repository' do
      dir = fake_mercurial(@tmpdir)
      repository.clone_url = "file://#{dir}"
      expect(job.is_mercurial?).to eq true
    end

    it 'is false on timeout' do
      IdentifyRepositoryJob.stub(:timeout).and_return(0.001)
      dir = fake_mercurial(@tmpdir)
      repository.clone_url = "file://#{dir}"
      expect(job.is_mercurial?).to eq false
    end

    it 'is false on git repository' do
      dir = fake_git(@tmpdir)
      repository.clone_url = "file://#{dir}"
      expect(job.is_mercurial?).to eq false
    end
  end

  describe '#clone_url' do
    it 'escapes shell commands' do
      repository.clone_url = "norepo || touch ohnoes"
      expect(File.exist?('ohnoes')).to eq false
      expect(job.clone_url).to include('\\ \\|\\|')

      repository.clone_url = "https://github.com/`touch ohnoes`"
      expect(File.exist?('ohnoes')).to eq false
      expect(job.clone_url).to include('\\`')
    end
  end
end
