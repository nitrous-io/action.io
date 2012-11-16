AIO.IdeConsoleController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  modelClass: AIO.ConsoleSession
  content: null
  fullscreen: false

  initialize: ->
    @set 'content', []
    @set 'fullscreen', false

  createTab: ->
    AIO.util.mixpanel 'ide:new_console_tab'
    @_super()

  reset: ->
    @set 'content', null
    @set 'fullscreen', false

