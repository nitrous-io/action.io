#= require term

window.AIO ||= {}

class AIO.BoxesTerminalPage
  constructor: (serverURI, boxId) ->
    @term = term = new Terminal(80, 6)
    term.open()
    @socket = socket = io.connect("#{serverURI}/ws/ssh")

    socket.on 'connect', ->
      socket.emit('start', boxId)

    socket.on 'start', (err) ->
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

    socket.on 'd', (data) ->
      term.write(data)

