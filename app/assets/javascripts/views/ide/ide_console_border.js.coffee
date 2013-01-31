AIO.IdeConsoleBorderView = Em.View.extend
  elementId: 'console_border'
  minConsoleHeight: null

  didInsertElement: ->
    @_super()
    @set 'minConsoleHeight', $('#ide_console_view').height()

  mouseDown: ->
    $sidebarView = $('#ide_sidebar_view')
    $editorView = $('#ide_editor_view')
    $consoleView = $('#ide_console_view')

    $('body').bind 'mousemove.console-resize', (event) =>
      newHeight = ( $consoleView.offset().top + $consoleView.height() ) - event.pageY
      if newHeight > @get 'minConsoleHeight'
        $consoleView.css 'height', newHeight
        $editorView.css 'paddingBottom', (newHeight + 4)
        $sidebarView.css 'paddingBottom', (newHeight + 4)

    $('body').bind 'mouseup.console-resize', (event) =>
      $('body').unbind 'mousemove.console-resize'
      $('body').unbind 'mouseup.console-resize'
