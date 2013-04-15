AIO.PublicKeysIndexController = Em.ObjectController.extend
  needs: ['publicKeys', 'application']

  refresh: ->
    @get('content').findAll()

  destroy: (publicKey) ->
    content = @get 'content'
    publicKey.destroyResource().done ->
      content.removeObject publicKey
