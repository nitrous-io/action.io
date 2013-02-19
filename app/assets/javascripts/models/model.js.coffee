AIO.Model = DS.Model.extend AIO.Validatable,
  loadJSON: (json) ->
    @get('store.adapter').didFindRecord @get('store'), @constructor, json, @get('id')

AIO.Model.reopenClass
  first: ->
    this.all().objectAtContent(0)
