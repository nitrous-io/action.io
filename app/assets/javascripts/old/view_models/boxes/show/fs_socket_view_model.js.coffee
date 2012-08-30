class AIO.FSSocketViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @socket = ko.computed =>
      @id() # force a dependency
      io.connect("#{@box_server_uri()}/ws/fs")

    if AIO.events
      AIO.events.on 'fetchFileList', this.onFetchFileList
      AIO.events.on 'fetchFileContent', this.onFetchFileContent
      AIO.events.on 'writeFile', this.onWriteFile
      AIO.events.on 'newFile', this.onNewFile

  connect: (callback) ->
    socket = @socket()
    socket.$events = {} # remove all events

    if socket.socket.connected
      socket.emit('start', @id()) if @id
    else
      socket.on 'connect', =>
        socket.emit('start', @id()) if @id

    socket.once 'start', (err) ->
      callback(err, socket)

  emit: ->
    socket = @socket()
    socket.emit.apply(socket, arguments)

  onFetchFileList: (path, vmid) =>
    this.emit('list', path, vmid)

  onFetchFileContent: (path, vmid) =>
    this.emit('read', path, vmid)

  onWriteFile: (path, vmid, content) =>
    this.emit('write', path, vmid, content)

  onNewFile: (path, content, callbackId) =>
    this.emit('new', path, content, callbackId)

  __destroy: ->
    if AIO.events
      AIO.events.off 'fetchFileList', this.onFetchFileList
      AIO.events.off 'fetchFileContent', this.onFetchFileContent
      AIO.events.off 'writeFile', this.onWriteFile
      AIO.events.off 'newFile', this.onNewFile
    @socket()?.$events = {}
    super()

