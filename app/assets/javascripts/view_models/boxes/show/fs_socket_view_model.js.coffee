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

  onFetchFileList: (path, cid) =>
    this.emit('list', path, cid)

  onFetchFileContent: (path, cid) =>
    this.emit('read', path, cid)

  onWriteFile: (path, cid, content) =>
    this.emit('write', path, cid, content)

  __destroy: ->
    if AIO.events
      AIO.events.off 'fetchFileList', this.onFetchFileList
      AIO.events.off 'fetchFileContent', this.onFetchFileContent
      AIO.events.off 'writeFile', this.onWriteFile
    @socket()?.$events = {}
    super()

