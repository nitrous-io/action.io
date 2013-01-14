AIO.IdeConsoleController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  modelClass: AIO.ConsoleSession
  content: null
  fullscreen: false

  initialize: ->
    @set 'content', []
    @set 'fullscreen', false

  createTab: (attrs={}) ->
    AIO.util.mixpanelIncrement 'ide:new_console_tab'
    @_super(attrs)

  reset: ->
    @set 'content', null
    @set 'fullscreen', false

