untitledFileCount = 0

class AIO.DocumentViewModel extends AIO.ViewModel
  constructor: (model, @file) ->
    super(model)
    @title = ko.computed =>
      if @file?
        @file.relativePath()
      else
        "untitled #{++untitledFileCount}"
    @active = ko.observable(true)

  setMode: (mode) =>
    @mode(mode.mode)

  toggleUseSoftTabs: =>
    @useSoftTabs(!@useSoftTabs())

  setTabSize: (size) =>
    @tabSize(size)

  setContent: (content) ->
    @model().setContent(content)

  setFile: (file) ->
    @file = file

