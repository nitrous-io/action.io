class AIO.BoxViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @expanded = ko.observable(false)
    @sshUri = ko.computed =>
      if @host?() && @port?()
        "ssh://action@#{@host()}:#{@port()}"

  toggleDetails: ->
    @expanded(!@expanded())

  openIDE: ->
    AIO.router.navigateTo "boxes/#{@id()}"

  terminateBox: ->
    userEnteredBoxName = window.prompt("THIS ACTION IS IRREVERSIBLE!!\n\nTo terminate this box, enter the name of the box:")
    if userEnteredBoxName == @name()
      @state('pending')
      @model().destroy()
    else
      window.alert("Termination cancelled.\n\nBox name does not match.")

