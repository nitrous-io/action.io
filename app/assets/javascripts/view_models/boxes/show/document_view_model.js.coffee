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

  setMode: (mode) =>
    @mode(mode.mode)

  toggleUseSoftTabs: =>
    @useSoftTabs(!@useSoftTabs())

  setTabSize: (size) =>
    @tabSize(size)

  saveFile: =>
    if @fileVM
      @fileVM.saveFile(@model().content())
    else
      # TODO: choose path and save

  setContent: (content) ->
    @model().setContent(content)

  __destroy: ->
    delete @fileVM
    super()
