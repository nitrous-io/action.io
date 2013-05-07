AIO.IdeEditorView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/editor'
  elementId: 'ide_editor_view'
  classNameBindings: ['controller.fullscreen:fullscreen']

  didInsertElement: ->
    @_super()
    $(window).bind 'resize.ideEditorView', _.bind(@resizeTabBarHeight, this)
    this.resizeTabBarHeight()

  willDestroyElement: ->
    @_super()
    $(window).unbind 'resize.ideEditorView'

  resizeTabBarHeight: (->
    Em.run.sync()
    Em.run.next this, ->
      if $header = @$ '> header'
        tabBarHeight = $header.outerHeight()
        $header.css 'margin-top', -tabBarHeight
        @$().css 'padding-top', tabBarHeight
  ).observes 'controller.@each.title'

  adjustPaddingBottomForConsole: (->
    consoleHeight = AIO.get 'router.ideLayoutController.consoleHeight'
    @$().css 'paddingBottom', (consoleHeight + 4)
  ).observes 'AIO.router.ideLayoutController.consoleHeight'

  adjustPaddingLeftForSidebar: (->
    sidebarWidth = AIO.get 'router.ideLayoutController.sidebarWidth'
    @$().css 'paddingLeft', (sidebarWidth + 4)
  ).observes 'AIO.router.ideLayoutController.sidebarWidth'

  didClickFullscreen: ->
    if mainMenuController = AIO.get 'router.ideMainMenuController'
      mainMenuController.viewToggleFullScreenEditor()
