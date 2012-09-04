AIO.PublicKeysIndexView = Em.View.extend
  templateName: 'templates/public_keys/index'
  classNames: ['app_page', 'public_keys', 'index']

  didClickDelete: (event) ->
    publicKey = event.context
    @get('controller').destroy(publicKey)

  didClickAddKey: ->
    AIO.get('router').transitionTo('publicKeys.new')

