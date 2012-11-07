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

    $(window).blur =>
      Terminal.focus = null
      @term.cursorBlink()
      if parentWindow
        consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
        if consoleSession.get 'focused'
          consoleSession.set 'focused', false

    $(window).blur()

    @term.originalFocus = @term.focus
    @term.focus = ->
      this.originalFocus()
      if parentWindow
        consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
        if !consoleSession.get 'focused'
          consoleSession.set 'focused', true

    @term.originalKeyDown = @term.keyDown
    @term.keyDown = (event) ->
      return if self.matchesFocusKeybinding event
        self.blurConsole event
      else if self.matchesCycleNextTabKeybinding event
        self.cycleNextConsole event
      else if self.matchesCyclePrevTabKeybinding event
        self.cyclePrevConsole event
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
    if parentWindow
      consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
      if consoleSession.get 'focused'
        consoleSession.set 'focused', false
      if document = parentWindow.AIO.get 'router.ideEditorController.activeTab'
        document.set 'focused', true
    Terminal.cancel event
    false

  cycleNextConsole: (event) ->
    if parentWindow
      ideConsoleController = parentWindow.AIO.get 'router.ideConsoleController'
      tabCount = parentWindow.AIO.get 'router.ideConsoleController.tabCount'
      ideConsoleController.makeNextTabActive() if tabCount > 1
    Terminal.cancel event
    false

  cyclePrevConsole: (event) ->
    if parentWindow
      ideConsoleController = parentWindow.AIO.get 'router.ideConsoleController'
      tabCount = parentWindow.AIO.get 'router.ideConsoleController.tabCount'
      ideConsoleController.makePrevTabActive() if tabCount > 1
    Terminal.cancel event
    false

