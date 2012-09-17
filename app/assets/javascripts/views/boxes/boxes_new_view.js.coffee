AIO.BoxesNewView = Em.View.extend
  templateName: 'templates/boxes/new'
  classNames: ['app_page', 'new']
  elementId: 'boxes_new_view'

  didClickSaveButton: (event) ->
    @get('controller').save()

  didClickCancelButton: (event) ->
    @get('controller').cancel()

