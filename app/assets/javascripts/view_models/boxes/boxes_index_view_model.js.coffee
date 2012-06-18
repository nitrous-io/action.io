class AIO.BoxesIndexViewModel extends AIO.ViewModel
  constructor: (collection) ->
    super()
    @allBoxes = kb.collectionObservable(collection, view_model: AIO.BoxViewModel)
    @boxes = ko.computed =>
      _.filter @allBoxes(), (boxViewModel) -> boxViewModel.id?
    this.refresh()

  newBox: ->
    if @boxes().length == 0
      AIO.router.navigate 'boxes/new', trigger: true
    else
      window.alert 'Sorry, you can only create one box during the private beta.'

  refresh: ->
    AIO.c.boxes.aio_fetch()

