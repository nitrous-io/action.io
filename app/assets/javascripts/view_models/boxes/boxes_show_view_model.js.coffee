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
    @editor = new AIO.EditorViewModel()

    @fsSocket.on 'list', (err, path, cid, fileList) ->
      return if err
      AIO.c.files.getByCid(cid)?.parseAndAddFileList(fileList)

    @fsSocket.on 'read', (err, path, cid, content) =>
      return if err
      if file = @rootFile.findFileByCid(cid)
        @editor.newDocumentWithFileAndContent(file, content)
        file.model().incrementLoading(false)

