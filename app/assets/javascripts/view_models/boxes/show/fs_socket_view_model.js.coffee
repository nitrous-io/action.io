class AIO.FSSocketViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @socket = ko.computed =>
      @id() # force a dependency
      io.connect("#{@box_server_uri()}/ws/fs")

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

  __destroy: ->
    @socket()?.$events = {}
    super()

