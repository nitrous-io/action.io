class AIO.BoxesShowViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    @currentUser = kb.viewModel(AIO.currentUser)
    @console = new AIO.ConsoleViewModel(model)

    activate: ->
      console.log('activate')

    close: ->
      console.log('close')

