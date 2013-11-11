AIO.Region = AIO.Resource.extend
  name        : null
  description : null
  state       : null

  resourceUrl: '/regions'
  resourceName: 'region'

  enabled: (->
    @get('state') != 'down'
  ).property 'state'

  goingDown: (->
    @get('state') == 'going_down'
  ).property 'state'

AIO.Region.reopenClass

  closestRegion: (callback) ->
    klass = this
    $.ajax('/regions/closest').done((json) ->
      model = klass.create json.region
      callback null, model
    ).fail (e) ->
      callback $.parseJSON(e.responseText).error
