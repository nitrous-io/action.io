class AIO.FSSocket
  constructor: (box) ->
    @socket = io.connect("#{box.get('box_server_uri')}/ws/fs")

    @socket.on 'connect', =>
      @socket.emit('start', box.get('id'))

    @socket.on 'list', (err, path, cid, fileList) =>
      return if err
      AIO.c.files.getByCid(cid)?.parseAndAddFileList(fileList)

  emit: ->
    @socket.emit.apply(@socket, arguments)

  on: ->
    @socket.on.apply(@socket, arguments)

