class AIO.FileViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @expanded = ko.observable(false)
    @loading = ko.observable(0)
    @opening = ko.observable(false)
    @files = kb.collectionObservable @model().files,
      view_model: AIO.FileViewModel
      sort_attribute: 'path'
      sorted_index: (vms, vm) ->
        _.sortedIndex vms, vm, (vm) ->
          vm.path().toLowerCase()

    @directory = ko.computed =>
      @root() || @path().slice(-1) == '/'

    @relativePath = ko.computed =>
      if @root()
        '~'
      else
        pathComponents = @path().split('/')
        if @directory()
          pathComponents.slice(-2)[0]
        else
          pathComponents.slice(-1)[0]

    @expandedSub = @expanded.subscribe (expanded) =>
      this.fetchFileList() if expanded

    AIO.events.on 'fileListReceived', (path, cid, fileList) =>
      model = @model()
      if cid == model.cid
        model.parseAndAddFileList(fileList)
        this.decrementLoading()
        this.opening(false)

    AIO.events.on 'fileContentReceived', (path, cid, content, editorVM) =>
      model = @model()
      if cid == model.cid
        unless editorVM.fileCidTabMap()[cid]
          editorVM.newDocumentWithFileVMAndContent(this, content)
        this.decrementLoading()
        this.opening(false)

    AIO.events.on 'fileWritten', (path, cid) =>
      this.decrementLoading()

  incrementLoading: ->
    @loading(@loading() + 1)

  decrementLoading: ->
    @loading(@loading() - 1)

  fetchFileList: ->
    if @directory()
      @opening(true)
      this.incrementLoading()
      @model().fetchFileList()

  fetchFileContent: ->
    unless @directory()
      @opening(true)
      this.incrementLoading()
      @model().fetchFileContent()

  findFileVMByCid: (cid) =>
    if cid == @model().cid
      return this
    for file in @files()
      break if file = file.findFileVMByCid(cid)
    return file || null

  openFile: ->
    unless @opening()
      if @directory()
        @expanded(!@expanded())
      else
        AIO.events.emit 'openTabForFileWithCid', @model().cid
        this.fetchFileContent()

  saveFile: (content) ->
    unless @directory()
      this.incrementLoading()
      model = @model()
      model.socket.emit('write', model.get('path'), model.cid, content)

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

  __destroy: ->
    @expandedSub?.dispose()
    delete @expandedSub
    super()

