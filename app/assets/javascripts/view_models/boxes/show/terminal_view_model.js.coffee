class AIO.TerminalViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @title = ko.observable('Console')
    @active = ko.observable(true)

