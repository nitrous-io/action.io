#= require jquery
#= require term

window.AIO ||= {}

class AIO.BoxesTerminalPage
  constructor: (serverURI, boxId) ->
    self = this
    @term = term = new Terminal(80, 6)
    term.open()

    $(window).blur =>
      Terminal.focus = null
      @term.cursorBlink()
      if parentWindow = window.parent
        consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
        if consoleSession.get 'focused'
          consoleSession.set 'focused', false

    $(window).blur()

    @term.originalFocus = @term.focus
    @term.focus = ->
      this.originalFocus()
      if parentWindow = window.parent
        consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
        if !consoleSession.get 'focused'
          consoleSession.set 'focused', true

    @term.originalKeyDown = @term.keyDown
    @term.keyDown = (event) ->
      if self.matchesFocusKeybinding event
        return self.blurConsole event

      else if self.matchesCycleNextTabKeybinding event
        return self.cycleNextConsole event

      else if self.matchesCyclePrevTabKeybinding event
        return self.cyclePrevConsole event

      else
        return this.originalKeyDown event

    @socket = socket = io.connect("#{serverURI}/ws/ssh")

    socket.on 'connect', ->
      socket.emit('start', boxId)

    socket.on 'ack-start', (err) ->
      return if err
      term.element.focus()
      socket.emit 'r', 80, 6

      term.handler = (data) ->
        socket.emit 'd', data

      term.on 'resize', (cols, rows) ->
        socket.emit 'r', cols, rows

      window.onresize = ->
        term.sizeToFit()

      window.onresize()

    socket.on 'p', (data) ->
      term.write(data)

  focus: ->
    window.focus()
    @term.focus()

  # keybinding is ctrl+shift+c
  matchesFocusKeybinding: (event) ->
    (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 67) ||
    (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 67)

  # keybinding is ctrl+shift+x
  matchesCycleNextTabKeybinding: (event) ->
    (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 88) ||
    (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 88)

  # keybinding is ctrl+shift+z
  matchesCyclePrevTabKeybinding: (event) ->
    (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 90) ||
    (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 90)

  blurConsole: (event) ->
    if parentWindow = window.parent
      consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
      if consoleSession.get 'focused'
        consoleSession.set 'focused', false
      if document = parentWindow.AIO.get 'router.ideEditorController.activeTab'
        document.set 'focused', true
    Terminal.cancel event
    return false

  cycleNextConsole: (event) ->
    if parentWindow = window.parent
      ideConsoleController = parentWindow.AIO.get 'router.ideConsoleController'
      tabCount = parentWindow.AIO.get 'router.ideConsoleController.tabCount'
      ideConsoleController.makeNextTabActive() if tabCount > 1
    Terminal.cancel event
    return false

  cyclePrevConsole: (event) ->
    if parentWindow = window.parent
      ideConsoleController = parentWindow.AIO.get 'router.ideConsoleController'
      tabCount = parentWindow.AIO.get 'router.ideConsoleController.tabCount'
      ideConsoleController.makePrevTabActive() if tabCount > 1
    Terminal.cancel event
    return false
