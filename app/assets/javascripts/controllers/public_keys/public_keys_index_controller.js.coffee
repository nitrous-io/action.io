AIO.PublicKeysIndexController = Em.ObjectController.extend
  contentBinding: 'AIO.router.publicKeysController'

  refresh: ->
    @get('content').findAll()

  destroy: (publicKey) ->
    content = @get 'content'
    publicKey.destroyResource().fail((e)->
      # TODO: handle failure
    ).done ->
      content.removeObject publicKey

