AIO.IdeConsoleController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  needs: ['ide', 'ideLayout', 'ideMainMenu', 'ideSidebar', 'ideEditor', 'ideConsole', 'ideCollaborators']
  modelClass: AIO.ConsoleSession
  content: null
  fullscreen: false

  initialize: ->
    @set 'content', []
    @set 'fullscreen', false

  createTab: (attrs={}) ->
    AIO.util.mixpanelIncrement 'ide_new_console_tab_count'
    @_super(attrs)

  reset: ->
    @set 'content', null
    @set 'fullscreen', false

