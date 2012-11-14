AIO.Box = AIO.Resource.extend
  name             : null
  host             : null
  state            : null
  box_template_id  : null
  owner_id         : null
  region_id        : null
  port             : null
  box_server_uri   : null
  public_key       : null

  resourceUrl: '/boxes'
  resourceName: 'box'
  resourceProperties: ['name', 'region_id', 'box_template_id']

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0
    region_id: (v) -> "needs to be selected" unless v
    box_template_id: (v) -> "needs to be selected" unless v

  expanded: false
  loading: false # when box control request is happening
  loadingPublicKey: false # when loading public key from server

  sshURI: (->
    host = @get 'host'
    port = @get 'port'
    if host && port
      "ssh://action@#{@get 'host'}:#{@get 'port'}"
  ).property 'host', 'port'

  boxHost: (->
    name = @get 'name'
    host = @get 'host'
    if name && host
      "#{@get 'name'}.#{@get 'host'}"
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

  working: (->
    !(_.include(['stopped', 'running', 'terminated', 'provisioning'], @get('state')))
  ).property 'state'

  finishLoadingPublicKey: (->
    @set 'loadingPublicKey', false
  ).observes 'public_key'

  start: -> @makeBoxControlRequest 'start'

  stop: -> @makeBoxControlRequest 'stop'

  terminate: ->
    @set 'loading', true
    $.ajax(
      type: 'DELETE'
      dataType: 'json'
      url: "#{@get 'resourceUrl'}/#{@get 'id'}"
    ).always =>
      @set 'loading', false

  readDefaultPublicKey: ->
    @set 'loadingPublicKey', true
    $.ajax
      type: 'GET'
      dataType: 'json'
      url: "#{@get 'resourceUrl'}/#{@get 'id'}/default_public_key"

  setupGithubKey: ->
    @makeBoxControlRequest 'setup_github_key'

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
