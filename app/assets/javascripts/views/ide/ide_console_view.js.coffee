AIO.IdeConsoleView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/console'
  elementId: 'ide_console_view'
  classNameBindings: ['controller.fullscreen:fullscreen', 'alwaysFullScreen:fullscreen']

  alwaysFullScreen: false
  termSyncEnabledBinding: Em.Binding.oneWay 'controller.box.term_sync_enabled'

  didClickFullScreen: ->
    if mainMenuController = AIO.get 'router.ideMainMenuController'
      mainMenuController.viewToggleFullScreenConsole()

  didInsertElement: ->
    @_super()
    $(window).bind 'resize.ideConsoleView', _.bind(@resizeTabBarHeight, this)
    this.didClickNew()

  didClickSyncSession: ->
    if consoleController = AIO.get 'router.ideConsoleController'
      consoleController.syncSessions()
      
  willDestroyElement: ->
    @_super()
    $(window).unbind 'resize.ideConsoleView'

  resizeTabBarHeight: (->
    Em.run.sync()
    Em.run.next this, ->
      if $header = @$ '> header'
        tabBarHeight = $header.outerHeight()
        $header.css 'margin-top', -tabBarHeight
        @$().css 'padding-top', tabBarHeight
  ).observes 'controller.length'
