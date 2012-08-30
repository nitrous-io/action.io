AIO.PublicKeysIndexView = Em.View.extend
  templateName: 'templates/public_keys/index'

  didClickDelete: (event) ->
    publicKey = event.context
    @get('controller').destroy(publicKey)

