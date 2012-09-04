AIO.BoxesNewView = Em.View.extend
  templateName: 'templates/boxes/new'
  classNames: ['app_page', 'boxes', 'new']

  didClickSaveButton: (event) ->
    @get('controller').save()

  didClickCancelButton: (event) ->
    @get('controller').cancel()

