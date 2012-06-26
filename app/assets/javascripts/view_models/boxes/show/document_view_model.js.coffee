untitledFileCount = 0

class AIO.DocumentViewModel extends AIO.ViewModel
  constructor: (model, @fileVM) ->
    super(model)
    @title = ko.computed =>
      if @fileVM?
        @fileVM.relativePath()
      else
        "untitled #{++untitledFileCount}"
    @active = ko.observable(true)

    window.setTimeout =>
      @model().initCodeMirror()
    , 0

  setMode: (mode) =>
    @mode(mode.mode)

  toggleSoftTabs: =>
    @softTabs(!@softTabs())

  setTabSize: (size) =>
    @tabSize(size)

  saveFile: =>
    if @fileVM
      @fileVM.saveFile(@model().get('content'))
    else
      # TODO: choose path and save

  __destroy: ->
    @model()?.cleanUp()
    delete @fileVM
    super()

