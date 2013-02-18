AIO.Model = DS.Model.extend AIO.Validatable,
  # if the record is not loaded, delay until it is loaded
  waitTilLoaded: (cb) ->
    return cb(this) if @get('isLoaded')
    this.one 'loadedData', => cb(this)

AIO.Model.reopenClass
  first: ->
    this.find this.all().get('content.firstObject.id')
