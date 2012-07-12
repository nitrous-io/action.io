class AIO.FileViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @expanded = ko.observable(false)
    @loading = ko.observable(0)
    @files = kb.collectionObservable @model().files,
      view_model: AIO.FileViewModel
      sort_attribute: 'path'
      sorted_index: (vms, vm) ->
        _.sortedIndex vms, vm, (vm) ->
          vm.path().toLowerCase()

    @directory = ko.computed =>
      @path().slice(-1) == '/'

    @relativePath = ko.computed =>
      path = @path()
      if path == '/'
        '~/'
      else
        pathComponents = path.split('/')
        if path.slice(-1) == '/'
          pathComponents.slice(-2).join('/')
        else
          pathComponents.slice(-1)[0]

    @expandedSub = @expanded.subscribe (expanded) =>
      this.fetchFileList() if expanded

    if AIO.events
      AIO.events.on 'fileListReceived', this.onFileListReceived
      AIO.events.on 'fileContentReceived', this.onFileContentReceived
      AIO.events.on 'fileWritten', this.onFileWritten

  incrementLoading: ->
    @loading(@loading() + 1)

  decrementLoading: ->
    @loading(@loading() - 1)

  fetchFileList: ->
    if @directory()
      this.incrementLoading()
      model = @model()
      AIO.events.emit('fetchFileList', model.get('path'), @vmid)

  fetchFileContent: ->
    unless @directory()
      this.incrementLoading()
      model = @model()
      AIO.events.emit('fetchFileContent', model.get('path'), @vmid)

  openFile: ->
    if @loading() == 0
      if @directory()
        @expanded(!@expanded())
      else
        AIO.events.emit('openTabForFileWithPath', @path())
        this.fetchFileContent()

  saveFile: (content) ->
    if @loading() == 0 && !@directory()
      this.incrementLoading()
      AIO.events.emit('writeFile', @path(), @vmid, content)

  refreshTree: =>
    unless @loading() > 0
      delay = 0

      for file in @files()
        delay += 330
        ((file, delay) ->
          window.setTimeout ->
            file.refreshTree()
          , delay
        )(file, delay)

      this.fetchFileList()

  onFileListReceived: (err, path, vmid, fileList) =>
    if vmid == @vmid
      unless err
        @model()?.parseAndAddFileList(fileList)
      this.decrementLoading()

  onFileContentReceived: (err, path, vmid, content, editorVM) =>
    if vmid == @vmid
      if err
        if err.indexOf('aio_not_text_file') != -1
          AIO.showAlertDialog('Could Not Open File', "#{@relativePath()} is not a text file.")
      else unless editorVM.tabForFileWithPath(path)
        editorVM.newDocumentWithFileVMAndContent(this, content)
      this.decrementLoading()

  onFileWritten: (err, path, vmid) =>
    if vmid == @vmid
      this.decrementLoading()

  __destroy: ->
    if AIO.events
      AIO.events.off 'fileListReceived', this.onFileListReceived
      AIO.events.off 'fileContentReceived', this.onFileContentReceived
      AIO.events.off 'fileWritten', this.onFileWritten
    @expandedSub?.dispose()
    delete @expandedSub
    @model().cleanUp()
    super()

