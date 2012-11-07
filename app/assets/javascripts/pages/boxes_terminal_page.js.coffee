#= require jquery
#= require term

window.AIO ||= {}

class AIO.BoxesTerminalPage
  constructor: (serverURI, boxId) ->
    @serverURI = serverURI
    @boxId = boxId

    parentWindow = window.parent
    parentWindow = null if parentWindow == window

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

    @term.focus2 = @term.focus
    @term.focus = ->
      this.focus2()
      if parentWindow
        consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
        if !consoleSession.get 'focused'
          consoleSession.set 'focused', true

    @term.keyDown2 = @term.keyDown
    @term.keyDown = (event) ->
      if (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 67) ||
         (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 67)
        if parentWindow
          consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
          if consoleSession.get 'focused'
            consoleSession.set 'focused', false
          if document = parentWindow.AIO.get 'router.ideEditorController.activeTab'
            document.set 'focused', true
        Terminal.cancel event
        return false
      else
        return this.keyDown2 event

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

