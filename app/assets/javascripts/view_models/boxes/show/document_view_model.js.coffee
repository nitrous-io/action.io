class AIO.DocumentViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @title = ko.observable('Document')
    @active = ko.observable(true)

  setMode: (mode) =>
    @mode(mode.mode)

  toggleUseSoftTabs: =>
    @useSoftTabs(!@useSoftTabs())

  setTabSize: (size) =>
    @tabSize(size)

