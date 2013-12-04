AIO.PusherController = Em.Controller.extend
  pusher: null
  channel: null
  maintenanceChannel: null
  channelName: (->
    if currentUserId = AIO.get 'currentUser.id'
      "private-user-#{currentUserId}"
  ).property 'AIO.currentUser.id'

  initialize: (pusherKey) ->
    if AIO.get('environment') == 'development'
      Pusher.log = (message) -> console.log message

    @set 'pusher', pusher = new Pusher pusherKey

    @set 'channel', channel = pusher.subscribe @get('channelName')

    @set 'maintenanceChannel', maintenanceChannel = pusher.subscribe "maintenance-channel"

    channel.bind 'pusher:subscription_error', =>
      window.setTimeout(=>
        pusher.subscribe @get('channelName')
      , 5000)

    channel.bind 'aio:box_updated', (json) ->
      json = json[AIO.Box::get 'resourceName']
      if box = AIO.get('router.boxesController').findById json.id
        box.deserialize json
        trackingData =
          boxTemplate: box.get('boxTemplate.name')
          region: box.get('region.name')

        AIO.util.mixpanel "box:#{box.get('state')}", trackingData

    channel.bind 'aio:billing_profile_updated', (json) ->
      json = json['billing_profile']
      if billingProfile = AIO.get('billingProfile') || AIO.BillingProfile.create()
        billingProfile.deserialize json
        # reset this flag to allow user to access upgrade page again
        billingProfile.set 'transactionProcessing', null
        AIO.set 'billingProfile', billingProfile

    channel.bind 'aio:read_default_public_key', (json) ->
      json = json[AIO.Box::get 'resourceName']
      if box = AIO.get('router.boxesController').findById json.id
        box.set 'loadingPublicKey', false
        if publicKey = json.public_key
          box.set 'public_key', publicKey
        else
          box.set 'publicKeyInfo', 'Public key (~/.ssh/id_rsa.pub) not found.'

    channel.bind 'aio:n2o_updated', (json) ->
      if currentUser = AIO.get('currentUser')
        n2o = json['n2o']
        currentUser.set 'max_n2o', n2o['max']
        currentUser.set 'used_n2o', n2o['used']

    channel.bind 'aio:add_public_key_to_github', (json) ->
      if box = AIO.get('router.boxesController').findById json[AIO.Box::get 'resourceName'].id
        box.set 'addingPublicKeyToGitHub', false
        message = switch json.status
          when 'ok'
            'Added to GitHub!'
          when 'fail'
            switch json.error
              when 'public_key_not_found'
                box.set 'public_key', null
                'Public key (~/.ssh/id_rsa.pub) not found.'
              when 'github_validation_failed'
                'Failed to add public key to GitHub (already added?)'
              else
                "Failed to add public key to GitHub. Please try again."
        box.set 'publicKeyInfo', message

    channel.bind 'aio:fetch_user_company', (json) ->
      if currentUser = AIO.get('currentUser')
        currentUser.set 'hasCompany', json

    channel.bind 'aio:box_info_response', (json) ->
      json = json[AIO.Box::get 'resourceName']
      if box = AIO.get('router.boxesController').findById json.id
        box.set 'memory_usage', json['memory_usage']
        box.set 'storage_usage', json['storage_usage']

    channel.bind 'aio:fetch_closest_region', (json) ->
      region = json[AIO.Region::get 'resourceName']
      AIO.get('router.boxesNewController').set 'closestRegionId', region?.id

    maintenanceChannel.bind 'aio:region_status', (regionStatus) ->
      return unless regionStatus.state? || regionStatus.region_id?
      if region = AIO.get('router.regionsController').findById regionStatus.region_id
        region.set 'state', regionStatus.state
