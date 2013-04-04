AIO.SftpSocket = Em.Object.extend
  connection: null
  socket: null
  box: null
  started: false
  startedFirstTime: false

  serverURIBinding: 'box.box_server_uri'

  connect: ->
    connection = new AIO.SocketConnection "#{@get 'serverURI'}/sock"
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

