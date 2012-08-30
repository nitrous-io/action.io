class aio.sockets.FSSocket
  constructor: (serverURI, boxId, callback) ->
    @socket = io.connect("#{serverURI}/ws/fs")

    @socket.on 'connect', =>
      @socket.emit('start', boxId)

    callback(@socket)

