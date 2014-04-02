App.PublicKeysIndexView = Em.View.extend
  templateName: 'templates/public-keys/index'
  classNames: ['app_page', 'index']
  elementId: 'public_keys_index_view'

  didClickDelete: (event) ->
    publicKey = event.context
    @get('controller').destroy publicKey

  didClickAddKey: ->
    App.get('router').transitionTo 'publicKeys.new'

  didClickRefresh: ->
    @get('controller').refresh()

