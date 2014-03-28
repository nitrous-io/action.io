AIO.PublicKeysIndexView = Em.View.extend
  templateName: 'templates/public_keys/index'
  classNames: ['app_page', 'index']
  elementId: 'public_keys_index_view'

  didClickDelete: (event) ->
    publicKey = event.context
    @get('controller').destroy publicKey

  didClickAddKey: ->
    AIO.get('router').transitionTo 'publicKeys.new'

  didClickRefresh: ->
    @get('controller').refresh()

