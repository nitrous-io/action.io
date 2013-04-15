AIO.PublicKeysIndexView = Em.View.extend
  templateName: 'templates/public_keys/index'
  classNames: ['app_page', 'index']
  elementId: 'public_keys_index_view'

  didClickDelete: (publicKey) ->
    @get('controller').destroy publicKey

  didClickAddKey: ->
    @get('controller').transitionToRoute 'public_keys.new'

  didClickRefresh: ->
    @get('controller').refresh()

