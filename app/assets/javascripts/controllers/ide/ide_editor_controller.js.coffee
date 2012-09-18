AIO.IdeEditorController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  modelClass: AIO.Document
  content: null

  initialize: ->
    @set 'content', []

  reset: ->
    @set 'content', null

  saveDocument: (document) ->
    fsSocket = AIO.get 'router.ideController.fsSocket'
    path = document.get 'path'
    if fsSocket && path
      path.incrementProperty 'loadCount'
      fsSocket.writeFile path.get('absolutePath'), document.get('content')

