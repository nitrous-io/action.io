class ImportGitHubKeysJob
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find(self.user_id)
    PublicKey.import_github_keys(user)
  end
end
