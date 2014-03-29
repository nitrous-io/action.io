AIO.ShoverSocket = AIO.BaseSocket.extend
  name: 'shover'

  serverURIBinding: 'AIO.shoverServerURI'
  serverName: 'shover'

  didConnect: ->
    socket = @get('socket')
    socket.setMaxListeners(100)

    socket.on 'aio:box_updated', (json) ->
      timestamp = json._t
      json = json[AIO.Box.rootKey]
      if box = AIO.Box.findById json.id
        lastBoxUpdatedTimestamp = box.get('lastBoxUpdatedTimestamp')
        if !lastBoxUpdatedTimestamp || lastBoxUpdatedTimestamp < timestamp
          box.set 'lastBoxUpdatedTimestamp', timestamp
          box.loadHash json
          trackingData =
            boxTemplate: box.get('boxTemplate.name')
            region: box.get('region.name')

          AIO.util.mixpanel "box:#{box.get('state')}", trackingData

    socket.on 'aio:snapshot_updated', (json) ->
      json = json[AIO.Snapshot.rootKey]
      if snapshot = AIO.Snapshot.findById json.id
        snapshot.loadHash(json)

    socket.on 'aio:subscription_updated', (json) ->
      json = json.subscription
      if subscription = AIO.get('subscription') || AIO.Subscription.create()
        subscription.loadHash(json)
        # Reset flag to allow user to access upgrade/change plan pages again.
        AIO.set 'currentUser.subscription_pending', false
        AIO.set 'subscription', subscription

    socket.on 'aio:billing_profile_updated', (json) ->
      json = json[AIO.BillingProfile.rootKey]
      if billingProfile = AIO.get('billingProfile') || AIO.BillingProfile.create()
        billingProfile.loadHash(json)
        AIO.set 'billingProfile', billingProfile

    socket.on 'aio:n2o_updated', (json) ->
      if currentUser = AIO.get('currentUser')
        n2o = json.n2o
        currentUser.set 'max_n2o', n2o.max
        currentUser.set 'used_n2o', n2o.used

    socket.on 'aio:delinquent_at_updated', (json) ->
      if currentUser = AIO.get('currentUser')
        currentUser.set 'delinquent_at', json.user.delinquent_at

    socket.on 'aio:read_default_public_key', (json) ->
      json = json[AIO.Box.rootKey]
      if box = AIO.Box.findById json.id
        box.set 'loadingPublicKey', false
        if publicKey = json.public_key
          box.set 'public_key', publicKey
        else
          box.set 'publicKeyInfo', 'Public key (~/.ssh/id_rsa.pub) not found.'

    socket.on 'aio:add_public_key_to_github', (json) ->
      if box = AIO.Box.findById json[AIO.Box.rootKey].id
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

    socket.on 'aio:box_info_response', (json) ->
      json = json[AIO.Box.rootKey]
      if box = AIO.Box.findById json.id
        box.set 'memory_usage', json.memory_usage
        box.set 'storage_usage', json.storage_usage

    socket.on 'aio:fetch_user_company', (json) ->
      if currentUser = AIO.get('currentUser')
        currentUser.set 'hasCompany', json.r

    socket.on 'aio:fetch_closest_region', (json) ->
      region = json[AIO.Region.rootKey]
      AIO.get('router.boxesNewController').set 'closestRegionId', region?.id

    socket.on 'aio:region_status', (regionStatus) ->
      return unless regionStatus.state? || regionStatus.region_id?
      if region = AIO.Region.findById regionStatus.region_id
        region.set 'state', regionStatus.state

    socket.on 'aio:parts_changed', (json) ->
      boxId = json.box_id
      if boxId == AIO.get('router.ideController.content.id')
        # ideAutopartsController will observe changes for this property and refresh
        AIO.set 'partsChanged', +new Date()

  didClose: ->
    socket = @get('socket')
    socket.removeAllListeners()
