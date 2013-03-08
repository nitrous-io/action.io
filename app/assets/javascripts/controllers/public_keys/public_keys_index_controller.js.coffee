AIO.PublicKeysIndexController = AIO.ResourceController.extend
  resourceType: AIO.PublicKey
  jsonRoot: 'public_keys'

  refresh: ->
    this.findAll()

  removePublicKey: (publicKey) ->
    publicKey.destroyResource().done =>
      this.removeObject publicKey

  didClickAddKey: ->
    this.transitionToRoute 'public_keys.new'

