class AIO.BoxesIndexViewModel extends AIO.ViewModel
  constructor: (collection) ->
    super()
    @allBoxes = kb.collectionObservable(collection, view_model: AIO.BoxViewModel)
    @boxes = ko.computed =>
      _.filter @allBoxes(), (boxVM) -> boxVM.id?
    this.refreshList()

  newBox: ->
    if _.filter(@boxes(), (boxVM) -> boxVM.state() != 'terminated').length > 0
      window.alert 'Sorry, you can only create one box during the private beta.'
      return
    AIO.router.navigate 'boxes/new', trigger: true

  refreshList: ->
    AIO.c.boxes.aio_fetch()

