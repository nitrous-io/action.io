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
    @fsSocket.connect (err) =>
      return if err
      @rootFile.expanded(true)
    @editor = new AIO.EditorViewModel()

    @fsSocket.on 'list', (err, path, cid, fileList) ->
      return if err # TODO: error handling
      AIO.c.files.getByCid(cid)?.parseAndAddFileList(fileList)

    @fsSocket.on 'read', (err, path, cid, content) =>
      return if err # TODO: error handling
      if file = @rootFile.findFileByCid(cid)
        @editor.newDocumentWithFileAndContent(file, content)
        file.model().incrementLoading(false)

    @fsSocket.on 'write', (err, path, cid) =>
      return if err # TODO: error handling
      AIO.c.files.getByCid(cid)?.incrementLoading(false)

