class AIO.BoxesShowViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @currentUser = kb.viewModel(AIO.currentUser)
    @console = new AIO.ConsoleViewModel(@model())
    @fsSocket = new AIO.FSSocketViewModel(@model())
    @rootFile = new AIO.FileViewModel(new AIO.File(root: true, socket: @fsSocket))
    @fsSocket.connect (err) =>
      return if err
      @rootFile.expanded(true)

