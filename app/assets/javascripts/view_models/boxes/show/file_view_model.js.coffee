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

    @expandedSubscription = @expanded.subscribe (expanded) =>
      @model().fetchFileList() if expanded && @directory()

  toggleExpanded: ->
    @expanded(!@expanded())

  __destroy: ->
    @expandedSubscription?.dispose()
    super()

