class AIO.BoxesIndexViewModel extends AIO.ViewModel
  constructor: (collection) ->
    allBoxes = kb.collectionObservable(collection, view_model: AIO.BoxViewModel)
    @boxes = ko.computed =>
      _.filter allBoxes(), (boxViewModel) -> boxViewModel.id?
    AIO.c.boxes.fetch(add: true)

  newBox: ->
    AIO.router.navigate 'boxes/new', trigger: true

