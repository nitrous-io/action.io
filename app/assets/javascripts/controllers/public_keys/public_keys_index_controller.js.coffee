AIO.PublicKeysIndexController = Em.ArrayController.extend
  refresh: ->
    AIO.PublicKey.find()

  destroy: (publicKey) ->
    publicKey.deleteRecord()
    @store.commit()

  didClickAddKey: ->
    this.transitionToRoute 'public_keys.new'

