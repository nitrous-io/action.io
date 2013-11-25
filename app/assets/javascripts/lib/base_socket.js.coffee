AIO.BaseSocket = Em.Object.extend
  name: 'base'
  connection: null
  socket: null
  serverURI: null

  connect: ->
    connection = new AIO.SocketConnection "#{@get 'serverURI'}/ws"
    socket = new AIO.Socket @get('name'), connection

    @setProperties
      connection: connection
      socket: socket

    connection.on 'authenticated', _.bind(@didAuthenticate, this)
    connection.on 'close', _.bind(@didClose, this)
    connection.connect()

  didAuthenticate: ->

  didClose: ->

  disconnect: ->
    if connection = @get 'connection'
      connection.destroy()
    @setProperties
      socket: null
      connection: null

  send: ->
    if socket = @get 'socket'
      socket.send _.toArray(arguments)...
