class AIO.FSSocketViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @socket = ko.computed =>
      @id() # force a dependency
      io.connect("#{@box_server_uri()}/ws/fs")

  connect: (callback) ->
    socket = @socket()

    if socket.socket.connected
      socket.emit('start', @id()) if @id
    else
      socket.on 'connect', =>
        socket.emit('start', @id()) if @id

      socket.on 'list', (err, path, cid, fileList) =>
        return if err
        AIO.c.files.getByCid(cid)?.parseAndAddFileList(fileList)

    socket.once 'start', (err) =>
      callback(err)

  emit: ->
    socket = @socket()
    socket.emit.apply(socket, arguments)

