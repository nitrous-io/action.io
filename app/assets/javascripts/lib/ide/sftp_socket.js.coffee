AIO.SftpSocket = Em.Object.extend
  socket: null
  box: null
  started: false
  startedFirstTime: false

  socketHostBinding: 'box.box_server_uri'

  socketURI: (->
    if socketHost = @get 'socketHost'
      "#{socketHost}/ws/sftp"
  ).property 'socketHost'

  connect: ->
    if socketURI = @get 'socketURI'
      if @get 'socket'
        this.disconnect()
        @get('socket').on 'disconnect', @connectNew.bind(this)
      else
        @connectNew()

  connectNew: ->
    @set 'started', false
    socket = io.connect @get('socketURI'), { 'force new connection': true }
    socket.$events = {}
    @set 'socket', socket
    boxId = @get 'box.id'

    if socket.socket.connected
      socket.emit 'start', boxId
    else
      socket.on 'connect', =>
        socket.emit 'start', boxId, =>
          @set 'started', true
          @set('startedFirstTime', true) if !@get 'startedFirstTime'

  disconnect: ->
    if socket = @get 'socket'
      socket.disconnect()
      socket.$events = {}
      @setProperties
        started: false
        box: null

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

