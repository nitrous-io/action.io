AIO.CollabInvite = AIO.Resource.extend
  email      : null
  state      : null
  created_at : null
  resourceName : 'invite'

AIO.CollabInvite.reopenClass
  fetch: (boxId, callback) ->
    klass = this
    $.ajax(
      type: 'GET'
      dataType: 'json'
      url: "/boxes/#{boxId}/invites"
    ).done((json) ->
      models = _.map json.invites, (attrs) ->
        klass.create attrs
      callback null, models
    ).fail (json) ->
      callback json
