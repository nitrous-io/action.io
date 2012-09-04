AIO.PublicKeysNewView = Em.View.extend
  templateName: 'templates/public_keys/new'
  classNames: ['app_page', 'public_keys', 'new']

  didClickSaveButton: (event) ->
    @get('controller').save()

  didClickCancelButton: (event) ->
    @get('controller').cancel()

