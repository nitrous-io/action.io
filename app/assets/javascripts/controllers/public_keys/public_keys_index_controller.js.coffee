AIO.PublicKeysIndexController = Em.ObjectController.extend
  contentBinding: 'AIO.router.publicKeysController'

  destroy: (publicKey) ->
    publicKey.destroyResource().fail((e)->
      # TODO: handle failure
    ).done =>
      this.removeObject(publicKey)

