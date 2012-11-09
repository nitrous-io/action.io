AIO.IdeConsoleView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/console'
  elementId: 'ide_console_view'
  classNameBindings: ['controller.fullscreen:fullscreen']

  didClickFullscreen: ->
    if mainMenuController = AIO.get 'router.ideMainMenuController'
      mainMenuController.viewToggleFullScreenConsole()

  didInsertElement: ->
    @_super()
    this.didClickNew()

