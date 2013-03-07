AIO.Model = DS.Model.extend AIO.Validatable

AIO.Model.reopenClass
  first: ->
    this.all().objectAtContent(0)
