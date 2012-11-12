class SetupGithubKey
  # Setup an SSH key integration for box and github. This
  # - post the public key to github
  # - send the private key to the specified box
  # - profit !!!
  #
  # box - instance of `Box` that we want to setup
  # ssh_key - instance of `SSHKey` that we want to setup
  def self.setup(box, ssh_key)
    github_user = GithubUser.init(box.owner)
    if github_user != GithubUser::NON_AUTHENTICATED_USER
      box_name = "actionio-#{box.name}"
      github_user.add_key box_name, ssh_key.ssh_public_key
      box.add_github_private_key ssh_key.private_key
    end
  end
end
