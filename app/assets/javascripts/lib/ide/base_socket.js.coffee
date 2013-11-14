AIO.BaseSocket = Em.Object.extend
  namespace: null
  connection: null
  socket: null
  box: null
  started: false
  startedFirstTime: false

  serverURIBinding: 'box.box_server_uri'

  connect: ->
    connection = new AIO.SocketConnection "#{@get 'serverURI'}/ws"
    socket = new AIO.Socket @get('namespace'), connection

    @setProperties
      connection: connection
      socket: socket

    connection.on 'authenticated', _.bind(@_didAuthenticate, this)
    connection.on 'close', _.bind(@_didClose, this)
    connection.connect()

  _didAuthenticate: ->
    boxId = @get 'box.id'
    socket = @get 'socket'

    socket.send 'init', =>
      socket.send 'start', boxId, =>
        @set 'started', true
        @set('startedFirstTime', true) if !@get('startedFirstTime')

  _didClose: ->
    @set 'started', false

  disconnect: ->
    if connection = @get 'connection'
      connection.destroy()
    @setProperties
      startedFirstTime: false
      started: false
      box: null
      socket: null
      connection: null

  send: ->
    if socket = @get 'socket'
      socket.send _.toArray(arguments)...
