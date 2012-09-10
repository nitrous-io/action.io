AIO.IdeConsoleView = AIO.IdeTabView.extend
  templateName: 'templates/ide/console'
  elementId: 'ide_console_view'
  classNameBindings: ['fullscreen']

  modelClass: AIO.ConsoleSession
  tabsBinding: 'AIO.router.ideController.consoleSessions'

  fullscreen: false

  didClickFullscreen: ->
    @set 'fullscreen', !@get('fullscreen')

