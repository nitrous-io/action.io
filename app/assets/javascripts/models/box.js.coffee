AIO.Box = AIO.Resource.extend
  container_name   : null
  name             : null
  host             : null
  state            : null
  box_template_id  : null
  owner_id         : null
  region_id        : null
  port             : null
  box_server_uri   : null

  memory           : null
  storage          : null
  memory_usage     : null
  storage_usage    : null

  public_key       : null
  publicKeyInfo    : null

  backend_available : null

  resourceUrl: '/boxes'
  resourceName: 'box'
  resourceProperties: ['name', 'region_id', 'box_template_id', 'memory', 'storage']

  errors: null

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0
    region_id: (v) -> "needs to be selected" unless v
    box_template_id: (v) -> "needs to be selected" unless v

  expanded: false
  loading: false # when box control request is happening
  loadingPublicKey: false # when loading public key from server
  addingPublicKeyToGitHub: false # when adding public key to github

  ownBox: (->
    if currentUserId = AIO.get('currentUser.id')
      currentUserId == @get('owner_id')
  ).property 'AIO.currentUser.id'

  notOwnBox: (->
    !@get('ownBox')
  ).property 'ownBox'

  sshURI: (->
    host = @get 'host'
    port = @get 'port'
    if host && port
      "ssh://action@#{@get 'host'}:#{@get 'port'}"
  ).property 'host', 'port'

  boxHost: (->
    name = @get 'container_name'
    host = @get 'host'
    if name && host
      "#{name}.#{host}"
  ).property 'name', 'host'

  region: (->
    AIO.get('router.regionsController').findById @get('region_id')
  ).property 'region_id'

  boxTemplate: (->
    AIO.get('router.boxTemplatesController').findById @get('box_template_id')
  ).property 'box_template_id'

  webTerminalPath: (->
    "#{@get 'resourceUrl'}/#{@get 'id'}/terminal"
  ).property 'id'

  stopped: (->
    @get('state') == 'stopped'
  ).property 'state'

  running: (->
    @get('state') == 'running'
  ).property 'state'

  terminated: (->
    @get('state') == 'terminated'
  ).property 'state'

  provisioning: (->
    @get('state') == 'provisioning'
  ).property 'state'

  failed: (->
    @get('state') == 'failed'
  ).property 'state'

  working: (->
    !(_.include(['stopped', 'running', 'terminated', 'provisioning', 'failed'], @get('state')))
  ).property 'state'

  stateForOrb: (->
    if @get 'region.enabled'
      @get 'state'
    else
      'under_maintenance'
  ).property 'state', 'region.enabled'

  stateForDisplay: (->
    switch state = @get 'state'
      when 'failed'
        'provisioning failed'
      when 'changing_specs'
        'changing specs'
      else
        state
  ).property 'state'

  start: -> this.makeBoxControlRequest 'start'

  stop: -> this.makeBoxControlRequest 'stop'

  restart: -> this.makeBoxControlRequest 'restart'

  provision: -> this.makeBoxControlRequest 'provision'

  terminate: ->
    @set 'loading', true
    $.ajax(
      type: 'DELETE'
      dataType: 'json'
      url: "#{@get 'resourceUrl'}/#{@get 'id'}"
    ).always =>
      @set 'loading', false
    .fail (e) =>
      if e.status == 422
        errors = @get 'errors' || {}
        errors = $.parseJSON(e.responseText).errors
        @set 'errors', errors

  readDefaultPublicKey: ->
    @set 'publicKeyInfo', null
    @set 'loadingPublicKey', true
    $.ajax(
      type: 'GET'
      dataType: 'json'
      url: "#{@get 'resourceUrl'}/#{@get 'id'}/default_public_key"
    ).fail (e) =>
      @set 'loadingPublicKey', false
      @set 'publicKeyInfo', 'Failed to fetch public key.'

  addPublicKeyToGitHub: ->
    @set 'publicKeyInfo', null
    @set 'addingPublicKeyToGitHub', true
    $.ajax(
      type: 'POST'
      dataType: 'json'
      url: "#{@get 'resourceUrl'}/#{@get 'id'}/add_public_key_to_github"
    ).fail =>
      @set 'addingPublicKeyToGitHub', false
      @set 'publicKeyInfo', 'Failed to add key to GitHub.'

  makeBoxControlRequest: (action) ->
    @set 'loading', true
    $.ajax(
      type: 'PUT'
      dataType: 'json'
      url: "#{@get 'resourceUrl'}/#{@get 'id'}/#{action}"
    ).always(=>
      @set 'loading', false
    ).done (json) =>
      json = json[@get 'resourceName']
      @deserialize json
    .fail (e) =>
      if e.status == 422
        errors = @get 'errors' || {}
        errors = $.parseJSON(e.responseText).errors
        @set 'errors', errors

  removeCollaborator: (username, callback) ->
    @set 'loading', true
    $.ajax(
      type: 'DELETE'
      dataType: 'json'
      url: "#{@get 'resourceUrl'}/#{@get 'id'}/collaborators/#{username}"
    ).always =>
      @set 'loading', false
    .done =>
      callback(true)
    .fail (e) =>
      if e.status == 422
        errors = @get 'errors' || {}
        errors = $.parseJSON(e.responseText).errors
        @set 'errors', errors
