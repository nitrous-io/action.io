App.PublicKeysNewView = Em.View.extend
  templateName: 'templates/public-keys/new'
  classNames: ['app_page', 'new']
  elementId: 'public_keys_new_view'

  didClickAddKey: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()

