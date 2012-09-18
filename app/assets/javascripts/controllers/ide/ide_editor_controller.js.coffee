AIO.IdeEditorController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  modelClass: AIO.Document
  content: null

  initialize: ->
    @set 'content', []

  reset: ->
    @set 'content', null

