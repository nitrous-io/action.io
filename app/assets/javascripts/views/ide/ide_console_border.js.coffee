AIO.IdeConsoleBorderView = Em.View.extend
  elementId: 'console_border'
  minConsoleHeight: null

  didInsertElement: ->
    @_super()
    @set 'minConsoleHeight', $('#ide_console_view').height()

  mouseDown: (event)->
    minConsoleHeight = @get 'minConsoleHeight'
    event.preventDefault()

    doResize = (baseY) ->
      $sidebarView = $('#ide_sidebar_view')
      $editorView = $('#ide_editor_view')
      $consoleView = $('#ide_console_view')

      newHeight = ( $consoleView.offset().top + $consoleView.height() ) - baseY
      if newHeight < minConsoleHeight
        newHeight = minConsoleHeight
        $('body').unbind 'mousemove.console-resize'
        $('body').unbind 'mouseup.console-resize'

      $consoleView.css 'height', newHeight
      $editorView.css 'paddingBottom', (newHeight + 4)
      $sidebarView.css 'paddingBottom', (newHeight + 4)

    $('body').bind
      'mousemove.console-resize': (event) ->
        doResize event.pageY
      'mouseup.console-resize': (event) ->
        $('body').unbind 'mousemove.console-resize'
        $('body').unbind 'mouseup.console-resize'
        $('#ide_console_view iframe').contents().find('body').unbind 'mousemove.console-resize'
        $('#ide_console_view iframe').contents().find('body').unbind 'mouseup.console-resize'

    $('#ide_console_view iframe').contents().find('body').bind
       'mousemove.console-resize': (event) ->
         doResize event.pageY
      'mouseup.console-resize': (event) ->
        console.log $(this)
        # $('body').unbind 'mousemove.console-resize'
        # $('body').unbind 'mouseup.console-resize'
        # $(this).unbind 'mousemove.console-resize'
        # $(this).unbind 'mouseup.console-resize'
