AIO.PublicKeysController = AIO.ResourceController.extend
  resourceType: AIO.PublicKey
  jsonRoot: 'public_keys'

  destroy: (publicKey) ->
    publicKey.destroyResource().fail((e)->
      # TODO: handle failure
    ).done =>
      this.removeObject(publicKey)

