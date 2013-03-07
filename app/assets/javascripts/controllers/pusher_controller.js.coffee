AIO.PusherController = Em.Controller.extend
  pusher: null
  channel: null
  currentUser: null
  channelName: (->
    if currentUserId = @get('currentUser.id')
      "private-user-#{currentUserId}"
  ).property 'currentUser'

  initialize: (pusherKey) ->
    if AIO.get('environment') == 'development'
      Pusher.log = (message) -> console.log message

    @set 'currentUser', AIO.get('currentUser')
    @set 'pusher', pusher = new Pusher pusherKey
    @set 'channel', channel = pusher.subscribe @get('channelName')

    channel.bind 'pusher:subscription_error', =>
      window.setTimeout(=>
        pusher.subscribe @get('channelName')
      , 5000)

    channel.bind 'aio:box_updated', (json) ->
      if box = AIO.Box.find json.box.id
        box.loadJSON json
        trackingData =
          boxTemplate: box.get('boxTemplate.name')
          region: box.get('region.name')
        AIO.util.mixpanel "box:#{box.get('state')}", trackingData

    channel.bind 'aio:read_default_public_key', (json) ->
      if box = AIO.Box.find(json.box.id)
        box.set 'loadingPublicKey', false
        if publicKey = json.box.public_key
          box.set 'publicKey', publicKey
        else
          box.set 'publicKeyInfo', 'Public key (~/.ssh/id_rsa.pub) not found.'

    channel.bind 'aio:add_public_key_to_github', (json) ->
      if box = AIO.Box.find json.box.id
        box.set 'addingPublicKeyToGitHub', false
        message = switch json.box.status
          when 'ok'
            'Added to GitHub!'
          when 'fail'
            switch json.box.error
              when 'public_key_not_found'
                box.set 'publicKey', null
                'Public key (~/.ssh/id_rsa.pub) not found.'
              when 'github_validation_failed'
                'Failed to add public key to GitHub (already added?)'
              else
                "Failed to add public key to GitHub. Please try again."
        box.set 'publicKeyInfo', message
