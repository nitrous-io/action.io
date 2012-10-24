AIO.SftpSocket = Em.Object.extend
  socket: null
  box: null
  started: false
  previouslyStarted: false

  delegate: null

  socketHostBinding: 'box.box_server_uri'

  socketURI: (->
    if socketHost = @get 'socketHost'
      "#{socketHost}/ws/sftp"
  ).property 'socketHost'

  connect: ->
    if socketURI = @get 'socketURI'
      this.disconnect() if @get 'socket'
      @set 'socket', socket = io.connect @get 'socketURI'
      socket.$events = {}

      boxId = @get 'box.id'

      socket.on 'disconnect', =>
        @set 'started', false
        delete io.sockets[@get 'socketHost']

      if socket.socket.connected
        socket.emit 'start', boxId
      else
        socket.on 'connect', ->
          socket.emit 'start', boxId

      socket.on 'ack-start', =>
        @set 'started', true
        if !@get 'previouslyStarted'
          @set 'previouslyStarted', true
          if delegate = @get 'delegate'
            delegate.sftpSocketDidStartForTheFirstTime this

      socket.on 'ack-list', (err, absolutePath, fileList) =>
        if delegate = @get 'delegate'
          delegate.sftpSocketDidReceiveFileList this, err, absolutePath, fileList

      socket.on 'ack-read', (err, absolutePath, content) =>
        if delegate = @get 'delegate'
          delegate.sftpSocketDidReceiveFileContent this, err, absolutePath, content

      socket.on 'ack-write', (err, absolutePath) =>
        if delegate = @get 'delegate'
          delegate.sftpSocketDidWriteFileContent this, err, absolutePath

      socket.on 'ack-writeNew', (err, absolutePath) =>
        if delegate = @get 'delegate'
          delegate.sftpSocketDidWriteNewFileContent this, err, absolutePath

      socket.on 'ack-upload', (err, absolutePath) =>
        if delegate = @get 'delegate'
          delegate.sftpSocketDidSendUploadToken this, err, absolutePath

  disconnect: ->
    if socket = @get 'socket'
      #socket.disconnect()
      socket.$events = {}
      @setProperties
        delegate: null
        started: false
        box: null
        socket: null

  emit: ->
    if socket = @get 'socket'
      socket.emit.apply socket, arguments

  fetchFileList: (absolutePath) ->
    this.emit 'list', absolutePath

  fetchFileContent: (absolutePath) ->
    this.emit 'read', absolutePath

  writeFile: (absolutePath, content) ->
    this.emit 'write', absolutePath, content

  writeNewFile: (absolutePath, content) ->
    this.emit 'writeNew', absolutePath, content

  sendUploadToken: (absolutePath, token) ->
    this.emit 'upload', absolutePath, token

