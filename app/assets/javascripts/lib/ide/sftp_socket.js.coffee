AIO.SftpSocket = Em.Object.extend
  socket: null
  box: null
  started: false
  startedFirstTime: false

  socketHostBinding: 'box.boxServerUri'

  socketURI: (->
    if socketHost = @get 'socketHost'
      "#{socketHost}/ws/sftp"
  ).property 'socketHost'

  connect: ->
    if socketURI = @get 'socketURI'
      console.log "socketuri", socketURI
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
        socket.on 'connect', =>
          console.log "connected"
          socket.emit 'start', boxId, =>
            console.log "STARTED"
            @set 'started', true
            @set('startedFirstTime', true) if !@get 'startedFirstTime'

  disconnect: ->
    if socket = @get 'socket'
      socket.disconnect()
      socket.$events = {}
      @setProperties
        started: false
        box: null
        socket: null

  emit: ->
    if socket = @get 'socket'
      socket.emit.apply socket, arguments

  fetchFileList: (absolutePath, callback) ->
    this.emit 'list', absolutePath, callback

  fetchFileContent: (absolutePath, callback) ->
    this.emit 'read', absolutePath, callback

  writeFile: (absolutePath, content, callback) ->
    this.emit 'write', absolutePath, content, callback

  writeNewFile: (absolutePath, content, callback) ->
    this.emit 'writeNew', absolutePath, content, callback

  makeDirectory: (absolutePath, callback) ->
    this.emit 'makeDir', absolutePath, callback

  sendUploadToken: (absolutePath, token, callback) ->
    this.emit 'upload', absolutePath, token, callback

  deleteFile: (absolutePath, callback) ->
    this.emit 'deleteFile', absolutePath, callback

  deleteDir: (absolutePath, callback) ->
    this.emit 'deleteDir', absolutePath, callback

