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

    @fileType = ko.computed =>
      if @fileVM?
        AIO.FTDetect.detect(@fileVM.relativePath())
      else
        'text/plain'

    @model()?.set(mode: @fileType())

    @fileTypeSub = @fileType.subscribe (fileType) =>
      @model()?.set(mode: fileType)

    window.setTimeout =>
      @model()?.initCodeMirror()
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
      AIO.showAlertDialog('Feature Coming Soon', 'Saving a new file is coming soon!')

  __destroy: ->
    @fileTypeSub?.dispose()
    @model()?.cleanUp()
    delete @fileVM
    super()

