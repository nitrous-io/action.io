AIO.IdeConsoleBorderView = Em.View.extend
  elementId: 'console_border'
  minConsoleHeight: null
  heightBinding: 'controller.controllers.ideLayout.consoleHeight'

  didInsertElement: ->
    @_super()
    @set 'minConsoleHeight', $('#ide_console_view').innerHeight()
    @set 'maxConsoleHeight', $('#ide_body').innerHeight()

  mouseDown: (event)->
    $consoleView = $('#ide_console_view')

    minConsoleHeight = @get 'minConsoleHeight'
    maxConsoleHeight = @get 'maxConsoleHeight'
    event.preventDefault()

    doResize = (pageY) =>
      newHeight = ( $consoleView.offset().top + $consoleView.innerHeight() ) - pageY

      if newHeight < minConsoleHeight
        newHeight = minConsoleHeight
        $('body').trigger 'mouseup.ideConsoleResize'

      if newHeight > maxConsoleHeight
        newHeight = maxConsoleHeight

      $consoleView.css 'height', newHeight
      @set 'height', newHeight

    $('body').on
      'mousemove.ideConsoleResize': (event, frameY) ->
        # for the bubbled up events we have to calcultate the pageY
        doResize (event.pageY || $consoleView.offset().top + frameY)

      'mouseup.ideConsoleResize': (event) ->
        $('body').off 'mousemove.ideConsoleResize'
        $('body').off 'mouseup.ideConsoleResize'
        $('#ide_console_view iframe').contents().find('body').off 'mouseup.ideConsoleResize'
        $('#ide_console_view iframe').contents().find('body').off 'mousemove.ideConsoleResize'

    # bubble-up the events to main body from iframe
    $('#ide_console_view iframe').contents().find('body').on
      'mousemove.ideConsoleResize': (event) ->
        $('body').trigger 'mousemove.ideConsoleResize', [ event.pageY ]

      'mouseup.ideConsoleResize': (event) ->
        $('body').trigger 'mouseup.ideConsoleResize'
