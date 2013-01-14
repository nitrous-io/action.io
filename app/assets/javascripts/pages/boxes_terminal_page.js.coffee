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
      else if self.matchesFullConsoleScreenKeybinding event
        self.makeConsoleFullScreen event
      else if self.matchesNewConsoleScreenKeybinding event
        self.createTab event
      else if self.matchesCloseConsoleScreenKeybinding event
        self.removeTab event
      else if self.matchesRefreshTreeKeybinding event
        self.refreshTree event
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

  # keybinding is shift+ctrl+f / ctrl+alt+f
  matchesFullConsoleScreenKeybinding: (event) ->
    (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 70) ||
    (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 70)

  # keybinding is shift+ctrl+n / ctrl+alt+n
  matchesNewConsoleScreenKeybinding: (event) ->
    (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 78) ||
    (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 78)

  # keybinding is shift+ctrl+w / ctrl+alt+w
  matchesCloseConsoleScreenKeybinding: (event) ->
    (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 87) ||
    (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 87)

  # keybinding is shift+ctrl+r / ctrl+alt+r
  matchesRefreshTreeKeybinding: (event) ->
    (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 82) ||
    (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 82)

  blurConsole: (event) ->
    if parentWindow
      consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
      if consoleSession.get 'focused'
        consoleSession.set 'focused', false
      if document = parentWindow.AIO.get 'router.ideEditorController.activeTab'
        document.set 'focused', true

      parentWindow.AIO.util.mixpanelIncrement 'ide:blur_console'

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

  makeConsoleFullScreen: (event) ->
    if parentWindow
      ideConsoleController = parentWindow.AIO.get 'router.ideConsoleController'
      ideConsoleController.toggleProperty 'fullscreen'
      parentWindow.AIO.util.mixpanelIncrement 'ide:toggle_console_fullscreen'
    Terminal.cancel event
    false

  createTab: (event) ->
    if parentWindow
      ideConsoleController = parentWindow.AIO.get 'router.ideConsoleController'
      ideConsoleController.createTab()
    Terminal.cancel event
    false

  removeTab: (event) ->
    if parentWindow
      ideConsoleController = parentWindow.AIO.get 'router.ideConsoleController'
      consoleSession = ideConsoleController.get 'activeTab'
      ideConsoleController.removeTab consoleSession
    Terminal.cancel event
    false

  refreshTree: (event) ->
    if parentWindow
      ideSidebarController = parentWindow.AIO.get 'router.ideSidebarController'
      if ideSidebarController.get 'sftpSocketReady'
        ideSidebarController.refreshAll()
    Terminal.cancel event
    false

