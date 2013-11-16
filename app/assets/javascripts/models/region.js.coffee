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
  fetchClosestRegion: ->
    $.ajax(type: 'GET', dataType: 'json', url: "#{this.proto().get 'resourceUrl'}/fetch_closest")
