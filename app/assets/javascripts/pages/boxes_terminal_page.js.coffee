#= require jquery
#= require term

parentWindow = window.parent
parentWindow = null if parentWindow == window

window.AIO ||= {}

class AIO.BoxesTerminalPage
  constructor: (serverURI, boxId) ->
    self = this

    @serverURI = serverURI
    @boxId = boxId

    @term = term = new Terminal(80, 6)
    term.open()

    @term.originalCursorBlink = @term.cursorBlink
    @term.cursorBlink = ->
      if Terminal.focus != this
        @cursorState = 1
      else
        if window.getSelection().toString()
          @cursorState = 0
        else
          @cursorState ^= 1
      this.refresh(@y, @y)

    $(window).blur =>
      Terminal.focus = null
      @term.cursorBlink()
      if parentWindow
        consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
        if consoleSession.get 'focused'
          consoleSession.set 'focused', false

    $(window).blur() unless document.hasFocus?()

    @term.originalFocus = @term.focus
    @term.focus = ->
      this.originalFocus()
      if parentWindow
        consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
        if !consoleSession.get 'focused'
          consoleSession.set 'focused', true

    @term.originalKeyDown = @term.keyDown
    @term.keyDown = (event) ->
      return if self.matchesBlurKeybinding event
        self.blurConsole event
      else if self.matchesNextTabKeybinding event
        self.makeNextTabActive event
      else if self.matchesPreviousTabKeybinding event
        self.makePreviousTabActive event
      else if self.matchesPasteKeybinding event
        # do nothing
      else if self.matchesCopyKeybinding event
        # do nothing
      else
        this.originalKeyDown event

    this.connect()
    # workaround for safari socket.io bug ----
    window.setTimeout(=>
      if !@socket.socket.connecting && !@socket.socket.connected && window.WebSocket
        tempWs = new WebSocket @serverURI.replace 'https', 'wss'
        window.setTimeout(=>
          io.sockets = {}
          this.connect()
        , 2000)
    , 2000)
    # ----

  connect: ->
    @socket = socket = io.connect("#{@serverURI}/ws/ssh")
    term = @term
    boxId = @boxId

    socket.on 'connect', ->
      socket.emit 'start', boxId, (err) ->
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

  # keybinding is shift+ctrl+c / ctrl+alt+c
  matchesBlurKeybinding: (event) ->
    (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 67) ||
    (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 67)

  # keybinding is shift+ctrl+] / ctrl+alt+]
  matchesNextTabKeybinding: (event) ->
    (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 221) ||
    (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 221)

  # keybinding is shift+ctrl+[ / ctrl+alt+[
  matchesPreviousTabKeybinding: (event) ->
    (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 219) ||
    (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 219)

  # keybinding is cmd-v / ctrl+shift+v
  matchesPasteKeybinding: (event) ->
    (Terminal.isMac && event.metaKey && event.keyCode == 86) ||
    (!Terminal.isMac && event.ctrlKey && event.shiftKey && event.keyCode == 86)

  # keybinding is cmd-c / ctrl+shift+c
  matchesCopyKeybinding: (event) ->
    (Terminal.isMac && event.metaKey && event.keyCode == 67) ||
    (!Terminal.isMac && event.ctrlKey && event.shiftKey && event.keyCode == 67)

  blurConsole: (event) ->
    if parentWindow
      consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
      if consoleSession.get 'focused'
        consoleSession.set 'focused', false
      if document = parentWindow.AIO.get 'router.ideEditorController.activeTab'
        document.set 'focused', true
    Terminal.cancel event
    false

  makeNextTabActive: (event) ->
    if parentWindow
      ideConsoleController = parentWindow.AIO.get 'router.ideConsoleController'
      ideConsoleController.makeNextTabActive()
    Terminal.cancel event
    false

  makePreviousTabActive: (event) ->
    if parentWindow
      ideConsoleController = parentWindow.AIO.get 'router.ideConsoleController'
      ideConsoleController.makePreviousTabActive()
    Terminal.cancel event
    false
