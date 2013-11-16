class ImportGitHubKeysJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find(user_id)
    PublicKey.import_github_keys(user)
  end
end
