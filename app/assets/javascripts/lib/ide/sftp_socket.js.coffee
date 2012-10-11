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

      socket.on 'start', =>
        @set 'started', true
        if !@get 'previouslyStarted'
          @set 'previouslyStarted', true
          if delegate = @get 'delegate'
            delegate.sftpSocketDidStartForTheFirstTime this

      socket.on 'list', (err, absolutePath, fileList) =>
        if delegate = @get 'delegate'
          delegate.sftpSocketDidReceiveFileList this, err, absolutePath, fileList

      socket.on 'read', (err, absolutePath, content) =>
        if delegate = @get 'delegate'
          delegate.sftpSocketDidReceiveFileContent this, err, absolutePath, content

      socket.on 'write', (err, absolutePath) =>
        if delegate = @get 'delegate'
          delegate.sftpSocketDidWriteFileContent this, err, absolutePath

      socket.on 'writeNew', (err, absolutePath) =>
        if delegate = @get 'delegate'
          delegate.sftpSocketDidWriteNewFileContent this, err, absolutePath

  disconnect: ->
    if socket = @get 'socket'
      socket.disconnect()
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

