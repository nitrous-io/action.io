AIO.IdeConsoleController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  needs: ['ide', 'ideMainMenu', 'ideLayout']
  modelClass: AIO.ConsoleSession
  content: null
  fullscreen: false

  initialize: ->
    @set 'content', []
    @set 'fullscreen', false
    this.createTab()

  createTab: (attrs={}) ->
    AIO.util.mixpanelIncrement 'ide_new_console_tab_count'
    @_super(attrs)

  reset: ->
    @set 'content', null
    @set 'fullscreen', false
