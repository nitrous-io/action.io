module SetupGithubKey
  # Setup an SSH key integration for box and github. This
  # - post the public key to github
  # - profit !!!
  # The public key should be created when the box is first created
  #
  # box - instance of `Box` that we want to setup
  def self.setup(box)
    box_owner_id = box.owner.id

    channel = Pusher["private-user-#{box_owner_id}"]
    github_user = GithubUser.new(box.owner)

    if github_user.authenticated?
      box_name = "nitrousio-#{box.name}"

      if public_key = ReadDefaultPublicKey.run(box)
        github_user.add_key box_name, public_key
        payload = {
          box: { id: box.id },
          status: 'ok'
        }
        Shover.publish box_owner_id, 'aio:add_public_key_to_github', payload
        channel.trigger 'aio:add_public_key_to_github', payload.to_json
      else
        payload = {
          box: { id: box.id },
          status: 'fail',
          error: 'public_key_not_found'
        }
        Shover.publish box_owner_id, 'aio:add_public_key_to_github', payload
        channel.trigger 'aio:add_public_key_to_github', payload.to_json
      end
    end
  # This happens when the request get 422: Validation failed. Typically this
  # meant the key is already in used
  rescue => error
    payload = {
      box: { id: box.id },
      status: 'fail',
      error: error.kind_of?(Octokit::UnprocessableEntity) ? 'github_validation_failed' : error.to_s
    }
    Shover.publish box_owner_id, 'aio:add_public_key_to_github', payload
    channel.trigger 'aio:add_public_key_to_github', payload.to_json
  end
end
