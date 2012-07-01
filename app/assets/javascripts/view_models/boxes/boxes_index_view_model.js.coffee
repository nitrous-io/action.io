class AIO.BoxesIndexViewModel extends AIO.ViewModel
  constructor: (collection) ->
    super()
    @currentUser = kb.viewModel(AIO.currentUser)
    @allBoxes = kb.collectionObservable(collection, view_model: AIO.BoxViewModel)
    @boxes = ko.computed =>
      if allBoxes = @allBoxes?()
        _.filter allBoxes, (boxVM) ->
          boxVM.id? || boxVM.state?() == 'provisioning'
    this.refreshList()

  newBox: ->
    if _.filter(@boxes(), (boxVM) -> boxVM.state() != 'terminated').length > 0
      window.alert 'Sorry, you can only create one box during the private beta.'
      return
    AIO.router.navigateTo 'boxes/new'

  refreshList: ->
    AIO.c.boxes.aio_fetch()

