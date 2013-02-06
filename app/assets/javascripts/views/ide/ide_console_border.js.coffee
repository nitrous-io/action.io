AIO.IdeConsoleBorderView = Em.View.extend
  elementId: 'console_border'
  minConsoleHeight: null

  didInsertElement: ->
    @_super()
    @set 'minConsoleHeight', $('#ide_console_view').innerHeight()
    @set 'maxConsoleHeight', $('#ide_body').innerHeight()

  mouseDown: (event)->
    $sidebarView = $('#ide_sidebar_view')
    $editorView = $('#ide_editor_view')
    $consoleView = $('#ide_console_view')

    minConsoleHeight = @get 'minConsoleHeight'
    maxConsoleHeight = @get 'maxConsoleHeight'
    event.preventDefault()

    doResize = (pageY) ->
      newHeight = ( $consoleView.offset().top + $consoleView.innerHeight() ) - pageY

      if newHeight < minConsoleHeight
        newHeight = minConsoleHeight
        $('body').trigger 'mouseup.console-resize'

      if newHeight > maxConsoleHeight
        newHeight = maxConsoleHeight

      $consoleView.css 'height', newHeight
      $editorView.css 'paddingBottom', (newHeight + 4)
      $sidebarView.css 'paddingBottom', (newHeight + 4)

    $('body').on
      'mousemove.console-resize': (event, frameY) ->
        # for the bubbled up events we have to calcultate the pageY
        doResize (event.pageY || $consoleView.offset().top + frameY)

      'mouseup.console-resize': (event) ->
        $('body').off 'mousemove.console-resize'
        $('body').off 'mouseup.console-resize'
        $('#ide_console_view iframe').contents().find('body').off 'mouseup.console-resize'
        $('#ide_console_view iframe').contents().find('body').off 'mousemove.console-resize'

    # bubble-up the events to main body from iframe
    $('#ide_console_view iframe').contents().find('body').on
      'mousemove.console-resize': (event) ->
        $('body').trigger 'mousemove.console-resize', [ event.pageY ]

      'mouseup.console-resize': (event) ->
        $('body').trigger 'mouseup.console-resize'
