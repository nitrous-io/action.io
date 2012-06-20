class AIO.BoxesShowViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @currentUser = kb.viewModel(AIO.currentUser)

    @previewUri = ko.computed =>
      if @name?() && @host?()
        "http://#{@name()}.#{@host()}:3000"

    @console = new AIO.ConsoleViewModel(@model())
    @fsSocket = new AIO.FSSocketViewModel(@model())
    @rootFile = new AIO.FileViewModel(new AIO.File(root: true, socket: @fsSocket))
    @editor = new AIO.EditorViewModel()

    @fsSocket.connect (err, socket) =>
      return if err
      @rootFile.expanded(true)

      socket.on 'list', (err, path, cid, fileList) =>
        return if err # TODO: error handling
        AIO.events.emit 'fileListReceived', path, cid, fileList

      socket.on 'read', (err, path, cid, content) =>
        return if err # TODO: error handling
        AIO.events.emit 'fileContentReceived', path, cid, content, @editor

      socket.on 'write', (err, path, cid) =>
        return if err # TODO: error handling
        AIO.events.emit 'fileWritten', path, cid

  showBetaNotice: ->
    $('#beta_notice').modal('show')

