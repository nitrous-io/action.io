AIO.PublicKeysNewView = Em.View.extend
  templateName: 'templates/public_keys/new'
  classNames: ['app_page', 'new']
  elementId: 'public_keys_new_view'

  didClickAddKey: (event) ->
    mixpanel?.track 'public_key_new:add'
    @get('controller').save()

  didClickCancel: (event) ->
    mixpanel?.track 'public_key_new:cancel'
    @get('controller').cancel()
