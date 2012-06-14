class AIO.BoxViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @expanded = ko.observable(false)
    @sshUri = ko.computed =>
      if @host && @port
        "ssh://action@#{@host()}:#{@port()}"

  toggleDetails: ->
    @expanded(!@expanded())

