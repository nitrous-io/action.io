class AIO.BoxesShowViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @currentUser = kb.viewModel(AIO.currentUser)

    @previewUri = ko.computed =>
      if @name?() && @host?()
        "http://#{@name()}.#{@host()}:3000"

    @console = new AIO.ConsoleViewModel(@model())
    @fsSocketReady = ko.observable(false)
    @fsSocket = new AIO.FSSocketViewModel(@model())
    @rootFile = new AIO.FileViewModel(new AIO.File(path: '/'))
    @editor = new AIO.EditorViewModel
    @saveDialog = new AIO.SaveDialogViewModel

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
        if err # TODO: error handling
          console.log err
          return
        AIO.events.emit 'fileWritten', path, cid

      socket.on 'new', (err, path, callbackId) =>
        cb = AIO.callbacks[callbackId]
        cb?(err, path)

      @fsSocketReady(true)

  showBetaNotice: ->
    $('#beta_notice').modal('show')

  comingSoon: ->
    AIO.showAlertDialog('Feature Coming Soon', 'This feature is coming soon!')

  __destroy: ->
    super()
    AIO.c.files.reset()
    AIO.c.documents.reset()

