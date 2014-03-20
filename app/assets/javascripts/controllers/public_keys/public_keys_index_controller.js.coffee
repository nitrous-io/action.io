AIO.PublicKeysIndexController = Em.ObjectController.extend
  content: (->
    AIO.PublicKey.all()
  ).property()

  refresh: ->
    @get('content').reload()

  destroy: (publicKey) ->
    publicKey.deleteRecord()
