class AIO.FileViewModel extends AIO.ViewModel
  constructor: (@model) ->
    @path = kb.observable(@model, 'path')
    @expanded = ko.observable(false)
    @root = kb.observable(@model, 'root')
    @files = kb.collectionObservable @model.files,
      view_model: AIO.FileViewModel
      sort_attribute: 'path'
      sorted_index: (vms, vm) ->
        _.sortedIndex vms, vm, (vm) ->
          vm.path().toLowerCase()

    @directory = ko.computed =>
      @root() || @path().slice(-1) == '/'

    @expandedHandler = ko.computed =>
      @model.fetchFileList() if @expanded() && @directory()
      null

    @relativePath = ko.computed =>
      if @root()
        '~'
      else
        pathComponents = @path().split('/')
        if @directory()
          pathComponents.slice(-2)[0]
        else
          pathComponents.slice(-1)[0]

  toggleExpanded: ->
    @expanded(!@expanded())

