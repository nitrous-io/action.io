AIO.BoxesNewView = Em.View.extend
  templateName: 'templates/boxes/new'

  didClickSaveButton: (event) ->
    @get('controller').save()

  didClickCancelButton: (event) ->
    @get('controller').cancel()

