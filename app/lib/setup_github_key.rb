class SetupGithubKey
  # Setup an SSH key integration for box and github. This
  # - post the public key to github
  # - profit !!!
  # The public key should be created when the box is first created
  #
  # box - instance of `Box` that we want to setup
  def self.setup(box)
    github_user = GithubUser.init(box.owner)
    if github_user != GithubUser::NON_AUTHENTICATED_USER
      box_name = "actionio-#{box.name}"
      public_key = ReadDefaultPublicKey.run box
      github_user.add_key box_name, public_key if public_key
    end
  end
end
