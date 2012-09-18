AIO.IdeConsoleController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  modelClass: AIO.ConsoleSession
  content: null

  initialize: ->
    @set 'content', []

  reset: ->
    @set 'content', null

