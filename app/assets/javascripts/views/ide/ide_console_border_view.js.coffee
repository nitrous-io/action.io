AIO.IdeConsoleBorderView = Em.View.extend
  elementId: 'console_border'
  minConsoleHeight: null
  heightBinding: 'AIO.router.ideLayoutController.consoleHeight'

  didInsertElement: ->
    @_super()
    height = $('#ide_console_view').innerHeight()
    #@set 'height', height
    @set 'minConsoleHeight', height
    @set 'maxConsoleHeight', $('#ide_body').innerHeight() - 4 # leave some room to resize back

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

      'mouseup.ideConsoleResize': (event) =>
        this.turnOffResizeEvents()

    # bubble-up the events to main body from iframe
    $('#ide_console_view iframe').contents().find('body').on
      'mousemove.ideConsoleResize': (event) ->
        $('body').trigger 'mousemove.ideConsoleResize', [ event.pageY ]

      'mouseup.ideConsoleResize': (event) ->
        $('body').trigger 'mouseup.ideConsoleResize'

  turnOffResizeEvents: ->
    $('body').off 'mousemove.ideConsoleResize'
    $('body').off 'mouseup.ideConsoleResize'
    $('#ide_console_view iframe').contents().find('body').off 'mouseup.ideConsoleResize'
    $('#ide_console_view iframe').contents().find('body').off 'mousemove.ideConsoleResize'

  willDestroyElement: ->
    @_super()
    this.turnOffResizeEvents()
