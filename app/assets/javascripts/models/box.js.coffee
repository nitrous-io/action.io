AIO.Box = AIO.Model.extend
  containerName : DS.attr('string')
  name          : DS.attr('string')
  host          : DS.attr('string')
  state         : DS.attr('string')
  port          : DS.attr('number')
  boxServerUri  : DS.attr('string')
  boxTemplate   : DS.belongsTo('AIO.BoxTemplate')
  owner         : DS.belongsTo('AIO.User')
  region        : DS.belongsTo('AIO.Region')
  publicKey     : null
  publicKeyInfo : null

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0
    region: (v) -> "needs to be selected" unless v.id
    boxTemplate: (v) -> "needs to be selected" unless v.id

  expanded: false
  loading: false # when box control request is happening
  loadingPublicKey: false # when loading public key from server
  addingPublicKeyToGitHub: false # when adding public key to github

  sshURI: (->
    host = @get 'host'
    port = @get 'port'
    if host && port
      "ssh://action@#{@get 'host'}:#{@get 'port'}"
  ).property 'host', 'port'

  boxHost: (->
    name = @get 'containerName'
    host = @get 'host'
    if name && host
      "#{name}.#{host}"
  ).property 'name', 'host'

  webTerminalPath: (->
    "/boxes/#{@get 'id'}/terminal"
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

  start: -> this.makeBoxControlRequest 'start'

  stop: -> this.makeBoxControlRequest 'stop'

  restart: -> this.makeBoxControlRequest 'restart'

  terminate: ->
    @set 'loading', true
    $.ajax(
      type: 'DELETE'
      dataType: 'json'
      url: "#{@get 'resourceUrl'}/#{@get 'id'}"
    ).always =>
      @set 'loading', false

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
