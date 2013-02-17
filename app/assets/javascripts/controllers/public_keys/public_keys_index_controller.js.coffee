AIO.PublicKeysIndexController = Em.ArrayController.extend
  needs: ['publicKeys']
  contentBinding: 'controllers.publicKeys.content'

  refresh: ->
    @get('content').findAll()

  destroy: (publicKey) ->
    content = @get 'content'
    publicKey.destroyResource().done ->
      content.removeObject publicKey

  didClickAddKey: ->
    this.transitionToRoute 'public_keys.new'

