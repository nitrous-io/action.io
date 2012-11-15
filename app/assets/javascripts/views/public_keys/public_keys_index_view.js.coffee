AIO.PublicKeysIndexView = Em.View.extend
  templateName: 'templates/public_keys/index'
  classNames: ['app_page', 'index']
  elementId: 'public_keys_index_view'

  didClickDelete: (event) ->
    mixpanel?.track 'public_key_index:delete'
    publicKey = event.context
    @get('controller').destroy publicKey

  didClickAddKey: ->
    mixpanel?.track 'public_key_index:add'
    AIO.get('router').transitionTo 'publicKeys.new'

  didClickRefresh: ->
    mixpanel?.track 'public_key_index:refresh'
    @get('controller').refresh()
