class AIO.BoxesNewViewModel extends AIO.ViewModel
  constructor: (@model) ->
    @name = kb.observable(model, 'name')
    @regions = kb.collectionObservable(AIO.c.regions, view_model: AIO.ReadOnlyViewModel)
    @region_id = ko.computed
      read: =>
        model.get('region')?.get('id')
      write: (id) =>
        model.set('region', AIO.c.regions.get(id), silent: true) # without silent: true, regions collection will get corrupted

  createBox: ->
    console.log @model.toJSON()

