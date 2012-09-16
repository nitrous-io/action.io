AIO.FSSocket = Em.Object.extend
  socket: null
  box: null
  started: false
  connected: false

  fileManagementDelegate: null
  fileContentDelegate: null

  socketURI: (->
    if boxServerURI = @get 'box.box_server_uri'
      "#{boxServerURI}/ws/fs"
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

      socket.on 'list', (err, path, vmid, fileList) =>
        if delegate = @get 'fileManagementDelegate'
          delegate.didReceiveFileList err, path, fileList

  disconnect: ->
    if socket = @get 'socket'
      socket.disconnect()
      socket.$events = {}
      @setProperties
        fileManagementDelegate: null
        fileContentDelegate: null
        started: false
        connected: false
        box: null
        socket: null

  emit: ->
    if socket = @get 'socket'
      socket.emit.apply socket, arguments

  fetchFileList: (path, vmid) ->
    this.emit 'list', path, vmid

