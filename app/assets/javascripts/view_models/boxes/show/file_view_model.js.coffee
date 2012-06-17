class AIO.FileViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @expanded = ko.observable(false)
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

  fetchFileList: ->
    if @directory()
      model = @model()
      model.incrementLoading(true)
      model.socket.emit('list', model.get('path'), model.cid)

  fetchFileContent: ->
    unless @directory()
      model = @model()
      model.incrementLoading(true)
      model.socket.emit('read', model.get('path'), model.cid)

  openFile: ->
    if @directory()
      @expanded(!@expanded())
    else
      this.fetchFileContent()

  saveFile: (content) ->
    unless @directory()
      model = @model()
      model.incrementLoading(true)
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

  findFileByCid: (cid) =>
    if cid == @model().cid
      return this
    for file in @files()
      break if file = file.findFileByCid(cid)
    return file || null

  __destroy: ->
    @expandedSub?.dispose()
    super()

