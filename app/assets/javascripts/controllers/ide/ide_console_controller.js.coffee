AIO.IdeConsoleController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  modelClass: AIO.ConsoleSession
  content: null
  fullscreen: false

  initialize: ->
    @set 'content', []

  reset: ->
    @set 'content', null
