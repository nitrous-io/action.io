class AIO.ConsoleViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @terminals = ko.observableArray([new AIO.TerminalViewModel(@model())])
    @fullscreen = ko.observable(false)

  newTerminal: ->
    terminal = new AIO.TerminalViewModel(@model())
    @terminals.push(terminal)
    this.activateTerminal(terminal)

  activateTerminal: (terminal) =>
    _.each @terminals(), (t) ->
      t.active(false) if t != terminal
    terminal.active(true)

  closeTerminal: (terminal) =>
    if terminal.active()
      terminal.active(false)
      index = @terminals.indexOf(terminal)
      index = (index - 1)
      index = 0 if index < 0
      if prevTerminal = @terminals()[index]
        this.activateTerminal(prevTerminal)
    @terminals.remove(terminal)

  toggleFullscreen: ->
    @fullscreen(!@fullscreen())

  __destroy: ->
    kb.utils.release(terminal) for terminal in @terminals()
    super()

