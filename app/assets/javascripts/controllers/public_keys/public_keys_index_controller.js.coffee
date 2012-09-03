AIO.PublicKeysIndexController = Em.ResourceController.extend
  resourceType: AIO.PublicKey
  jsonRoot: 'public_keys'

  destroy: (publicKey) ->
    publicKey.destroyResource()
      .fail (e) ->
        console.log e
      .done =>
        this.removeObject(publicKey)

