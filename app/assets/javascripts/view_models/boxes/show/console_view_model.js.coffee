class AIO.ConsoleViewModel extends AIO.TabbedViewModel
  constructor: (model) ->
    super(model)
    @fullscreen = ko.observable(false)
    this.newTerminal()

  newTerminal: ->
    this.newTab(new AIO.TerminalViewModel(@model()))

  toggleFullscreen: ->
    @fullscreen(!@fullscreen())

