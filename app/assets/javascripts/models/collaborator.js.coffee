AIO.Collaborator = AIO.Resource.extend
  username      : null
  full_name     : null
  gravatar_hash : null
  created_at    : null

  resourceName: 'collaborator'

  removing: false

  gravatarUrl: (->
    if gravatar_hash = @get 'gravatar_hash'
      "http://www.gravatar.com/avatar/#{gravatar_hash}?s=20"
  ).property 'gravatar_hash'

  remove: (boxId, callback) ->
    @set 'removing', true
    $.ajax(
      type: 'DELETE'
      dataType: 'json'
      url: "/boxes/#{boxId}/collaborators/#{@get 'username'}"
    ).done((json) ->
      callback null
    ).fail((json) ->
      callback json
    ).always =>
      @set 'removing', false

AIO.Collaborator.reopenClass
  fetch: (boxId, callback) ->
    klass = this
    $.ajax(
      type: 'GET'
      dataType: 'json'
      url: "/boxes/#{boxId}/collaborators"
    ).done((json) ->
      models = _.map json.collaborators, (attrs) ->
        klass.create attrs
      callback null, models
    ).fail (json) ->
      callback json

  add: (boxId, username, callback) ->
    klass = this
    $.ajax(
      type: 'PUT'
      dataType: 'json'
      url: "/boxes/#{boxId}/collaborators/#{username}"
    ).done((json) ->
      model = if json?.collaborator?
        klass.create json.collaborator
      callback null, model
    ).fail (json) ->
      callback json

  notifyMention: (mention, boxId) ->
    $.ajax
      type: 'POST'
      dataType: 'json'
      url: "/boxes/#{boxId}/collaborators/#{mention}/notify"
