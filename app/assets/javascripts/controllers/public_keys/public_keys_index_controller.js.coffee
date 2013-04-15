AIO.PublicKeysIndexController = Em.ObjectController.extend
  needs: ['publicKeys']

  refresh: ->
    @get('content').findAll()

  destroy: (publicKey) ->
    content = @get 'content'
    publicKey.destroyResource().done ->
      content.removeObject publicKey

