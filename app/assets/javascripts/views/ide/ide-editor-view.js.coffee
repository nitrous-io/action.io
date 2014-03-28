AIO.IdeEditorView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/editor'
  elementId: 'ide_editor_view'
  classNameBindings: ['controller.fullscreen:fullscreen']

  didInsertElement: ->
    @_super()
    $(window).bind 'resize.ideEditorView', _.bind(@resizeTabBarHeight, this)
    this.resizeTabBarHeight()
    this._sidebarWidthDidChange()
    this._collaborationPaneWidthDidChange()
    this._consoleHeightDidChange()

  willDestroyElement: ->
    @_super()
    $(window).unbind 'resize.ideEditorView'

  didClickChat: ->
    AIO.set 'router.ideLayoutController.collaborationPaneHidden', false
    this.hideChatNotification()

  didClickFullScreen: ->
    if mainMenuController = AIO.get 'router.ideMainMenuController'
      mainMenuController.viewToggleFullScreenEditor()

  resizeTabBarHeight: (->
    Em.run.sync()
    Em.run.next this, ->
      if $header = @$ '> header'
        tabBarHeight = $header.outerHeight()
        $header.css 'margin-top', -tabBarHeight
        @$().css 'padding-top', tabBarHeight
  ).observes 'controller.@each.title'

  showChatNotifcation: (->
    controller = @get 'controller'
    if chatNotification = controller.get 'chatNotification'
      $('.chat_notification.popover').show()
  ).observes 'controller.chatNotification'

  hideChatNotification: ->
    $('.chat_notification.popover').hide()
    controller = @get 'controller'
    controller.set 'chatNotification', null

  _consoleHeightDidChange: (->
    consoleHeight = AIO.get 'router.ideLayoutController.consoleHeight'
    @$().css 'paddingBottom', (consoleHeight + 4)
  ).observes 'AIO.router.ideLayoutController.consoleHeight'

  _sidebarWidthDidChange: (->
    paneWidth = AIO.get 'router.ideLayoutController.sidebarWidth'
    @$().css 'paddingLeft', (paneWidth + 4)
  ).observes 'AIO.router.ideLayoutController.sidebarWidth'

  _collaborationPaneWidthDidChange: (->
    padding = if AIO.get 'router.ideLayoutController.collaborationPaneHidden'
      0
    else
      paneWidth = AIO.get('router.ideLayoutController.collaborationPaneWidth') || 0
      paneWidth + 4
    @$().css 'paddingRight', padding
  ).observes(
    'AIO.router.ideLayoutController.collaborationPaneWidth',
    'AIO.router.ideLayoutController.collaborationPaneHidden'
  )
