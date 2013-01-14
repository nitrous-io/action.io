module SetupGithubKey
  # Setup an SSH key integration for box and github. This
  # - post the public key to github
  # - profit !!!
  # The public key should be created when the box is first created
  #
  # box - instance of `Box` that we want to setup
  def self.setup(box)
    channel = Pusher["private-user-#{box.owner.id}"]
    github_user = GithubUser.init(box.owner)
    if github_user != GithubUser::NON_AUTHENTICATED_USER
      box_name = "actionio-#{box.name}"

      if public_key = ReadDefaultPublicKey.run(box)
        github_user.add_key box_name, public_key
        METRICS.increment 'users.github.uploaded_ssh_key'
        channel.trigger 'aio:add_public_key_to_github', {
          box: { id: box.id },
          status: 'ok'
        }.to_json
      else
        channel.trigger 'aio:add_public_key_to_github', {
          box: { id: box.id },
          status: 'fail',
          error: 'public_key_not_found'
        }.to_json
      end
    end
  # This happens when the request get 422: Validation failed. Typically this
  # meant the key is already in used
  rescue => error
    channel.trigger 'aio:add_public_key_to_github', {
      box: { id: box.id },
      status: 'fail',
      error: error.kind_of?(Octokit::UnprocessableEntity) ? 'github_validation_failed' : error.to_s
    }.to_json
  end
end
