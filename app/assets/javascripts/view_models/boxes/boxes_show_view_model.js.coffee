class AIO.BoxesShowViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @currentUser = kb.viewModel(AIO.currentUser)
    @console = new AIO.ConsoleViewModel(model)
    @fsSocket = new AIO.FSSocket(model)
    @rootFile = new AIO.FileViewModel(new AIO.File(root: true, socket: @fsSocket))
    @fsSocket.socket.on 'start', (err) =>
      return if err
      @rootFile.expanded(true)

