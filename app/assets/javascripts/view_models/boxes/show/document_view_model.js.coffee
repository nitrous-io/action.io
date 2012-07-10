untitledFileCount = 0

class AIO.DocumentViewModel extends AIO.ViewModel
  constructor: (model, @fileVM) ->
    super(model)
    @fileVMObs = ko.observable(@fileVM)
    @title = ko.computed =>
      fileVM = @fileVMObs()
      if fileVM
        fileVM.relativePath()
      else
        "untitled #{++untitledFileCount}"
    @active = ko.observable(true)

    @fileType = ko.computed =>
      fileVM = @fileVMObs()
      if fileVM
        AIO.FTDetect.detect(fileVM.relativePath())
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
      @fileVM.model().save(@content())
    else
      AIO.events?.emit('showSaveDialog', this)

  __destroy: ->
    @fileVMObs(null)
    @fileTypeSub?.dispose()
    @model()?.cleanUp()
    delete @fileVM
    super()

