AIO.IdeConsoleController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  modelClass: AIO.ConsoleSession
  content: null
  fullscreen: false

  initialize: ->
    @set 'content', []
    @set 'fullscreen', false

  reset: ->
    @set 'content', null
    @set 'fullscreen', false

