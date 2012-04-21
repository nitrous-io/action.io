class ImportGitHubKeysJob
  @queue = :external_api_jobs

  def self.perform(user_id)
    user = User.find(user_id)
    PublicKey.import_github_keys(user)
  end
end
