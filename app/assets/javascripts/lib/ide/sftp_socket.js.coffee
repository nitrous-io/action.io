AIO.SftpSocket = Em.Object.extend
  socket: null
  box: null
  started: false
  connected: false

  delegate: null

  socketURI: (->
    if boxServerURI = @get 'box.box_server_uri'
      "#{boxServerURI}/ws/sftp"
  ).property 'box.box_server_uri'

  connect: ->
    if socketURI = @get 'socketURI'
      this.disconnect() if @get 'socket'
      @set 'socket', socket = io.connect @get 'socketURI'
      socket.$events = {}

      boxId = @get 'box.id'

      socket.on 'connect', =>
        @set 'connected', true

      socket.on 'disconnect', =>
        @set 'connected', false

      if socket.socket.connected
        socket.emit 'start', boxId
      else
        socket.once 'connect', ->
          socket.emit 'start', boxId

      socket.once 'start', =>
        @set 'started', true

      socket.on 'ls', (err, absolutePath, fileList) =>
        if delegate = @get 'delegate'
          delegate.didReceiveFileList err, absolutePath, fileList

      socket.on 'get', (err, absolutePath, content) =>
        if delegate = @get 'delegate'
          delegate.didReceiveFileContent err, absolutePath, content

      socket.on 'put', (err, absolutePath) =>
        if delegate = @get 'delegate'
          delegate.didWriteFileContent err, absolutePath

      socket.on 'new', (err, absolutePath) =>
        if delegate = @get 'delegate'
          delegate.didWriteNewFileContent err, absolutePath

  disconnect: ->
    if socket = @get 'socket'
      socket.disconnect()
      socket.$events = {}
      @setProperties
        delegate: null
        started: false
        connected: false
        box: null
        socket: null

  emit: ->
    if socket = @get 'socket'
      socket.emit.apply socket, arguments

  fetchFileList: (absolutePath) ->
    this.emit 'ls', absolutePath

  fetchFileContent: (absolutePath) ->
    this.emit 'get', absolutePath

  writeFile: (absolutePath, content) ->
    this.emit 'put', absolutePath, content, true

  writeNewFile: (absolutePath, content) ->
    this.emit 'put', absolutePath, content, false

