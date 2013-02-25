AIO.Model = DS.Model.extend AIO.Validatable,
  loadJSON: (data) ->
    store = @get('store')
    klass = this.constructor
    store.adapterForType(klass).load store, klass, data

AIO.Model.reopenClass
  first: ->
    this.all().objectAtContent(0)
