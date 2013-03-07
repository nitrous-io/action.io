AIO.IdeEditorView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/editor'
  elementId: 'ide_editor_view'

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
    consoleHeight = @get 'controller.controllers.ideLayout.consoleHeight'
    @$().css 'paddingBottom', (consoleHeight + 4)
  ).observes 'controller.controllers.ideLayout.consoleHeight'

  adjustPaddingLeftForSidebar: (->
    sidebarWidth = @get 'controller.controllers.ideLayout.sidebarWidth'
    @$().css 'paddingLeft', (sidebarWidth + 4)
  ).observes 'controller.controllers.ideLayout.sidebarWidth'
