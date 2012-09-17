AIO.PublicKeysNewView = Em.View.extend
  templateName: 'templates/public_keys/new'
  classNames: ['app_page', 'new']
  elementId: 'public_keys_new_view'

  didClickSaveButton: (event) ->
    @get('controller').save()

  didClickCancelButton: (event) ->
    @get('controller').cancel()

