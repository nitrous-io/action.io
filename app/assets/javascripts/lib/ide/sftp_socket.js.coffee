AIO.SftpSocket = Em.Object.extend
  connection: null
  socket: null
  eventBuffer: []
  box: null
  connected: false
  connectedFirstTime: false

  serverURIBinding: 'box.box_server_uri'

  connect: ->
    connection = new AIO.SocketConnection "#{@get 'serverURI'}/ws"
    socket = new AIO.Socket 'sftp', connection

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
        @set 'connected', true

        unless @get('connectedFirstTime')
          @set('connectedFirstTime', true)
        else
          this._processEventBuffer()

  _didClose: ->
    @set 'started', false

  disconnect: ->
    if connection = @get 'connection'
      connection.destroy()
    @setProperties
      connectedFirstTime: false
      connected: false
      box: null
      socket: null
      connection: null

  send: ->
    args = _.toArray(arguments)
    event = args[0]

    # exclude read events
    unless event in [ 'list', 'read' ]
      eventBuffer = @get 'eventBuffer'
      eventId = eventBuffer.length

      if _.isFunction(_.last args)
        originalCallback = args.pop()
        originalCallback()

      args.push( =>
        eventBuffer[eventId] = null
        originalCallback.apply null, _.toArray(arguments)
      )

      eventBuffer.push args

    if socket = @get 'socket'
      socket.send args...

  _processEventBuffer: ->
    eventBuffer = @get 'eventBuffer'
    socket = @get 'socket'

    console.log eventBuffer
    if socket && eventBuffer && eventBuffer.length
      _.each eventBuffer, (event) ->
        socket.send event...

  fetchFileList: (absolutePath, callback) ->
    this.send 'list', absolutePath, callback

  fetchFileContent: (absolutePath, callback) ->
    this.send 'read', absolutePath, callback

  writeFile: (absolutePath, content, callback) ->
    this.send 'write', absolutePath, content, callback

  writeNewFile: (absolutePath, content, callback) ->
    this.send 'writeNew', absolutePath, content, callback

  makeDirectory: (absolutePath, callback) ->
    this.send 'makeDir', absolutePath, callback

  sendUploadToken: (absolutePath, token, callback) ->
    this.send 'upload', absolutePath, token, callback

  deleteFile: (absolutePath, callback) ->
    this.send 'deleteFile', absolutePath, callback

  deleteDir: (absolutePath, callback) ->
    this.send 'deleteDir', absolutePath, callback

  rename: (currentPath, newPath, callback) ->
    this.send 'rename', currentPath, newPath, callback
