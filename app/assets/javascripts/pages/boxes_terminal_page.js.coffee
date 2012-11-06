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

    @term.focus2 = @term.focus
    @term.focus = ->
      this.focus2()
      if parentWindow = window.parent
        consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
        if !consoleSession.get 'focused'
          consoleSession.set 'focused', true

    @term.keyDown2 = @term.keyDown
    @term.keyDown = (event) ->
      if (Terminal.isMac && event.shiftKey && event.ctrlKey && event.keyCode == 67) ||
         (!Terminal.isMac && event.ctrlKey && event.altKey && event.keyCode == 67)
        if parentWindow = window.parent
          consoleSession = parentWindow.AIO.get 'router.ideConsoleController.activeTab'
          if consoleSession.get 'focused'
            consoleSession.set 'focused', false
          if document = parentWindow.AIO.get 'router.ideEditorController.activeTab'
            document.set 'focused', true
        Terminal.cancel event
        return false
      else
        return this.keyDown2 event

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

