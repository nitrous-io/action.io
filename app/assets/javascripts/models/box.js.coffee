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
  version          : null
  custom_domain    : null
  custom_domains_allowed : null

  source_snapshot_id:  null

  memory           : null
  storage          : null
  memory_usage     : null
  storage_usage    : null

  n2o_cost         : null

  cpu_multiplier   : null
  virtual_memory   : null
  expected_cpu_multiplier: null
  expected_virtual_memory: null

  auth_username    : null
  auth_password    : null

  public_key       : null
  publicKeyInfo    : null

  backend_available : null
  force_shutdown    : null

  resourceUrl: '/boxes'
  resourceName: 'box'
  resourceProperties: ['name', 'region_id', 'box_template_id', 'source_snapshot_id', 'memory', 'storage']

  lastBoxUpdatedTimestamp: null # to ignore late-delivered aio:box_updated shover event

  errors: null

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0
    region_id: (v) -> "needs to be selected" unless v

  randomNames: [
    'winterfell'
    'white-harbor'
    'pyke'
    'riverrun'
    'harrenhal'
    'eyrie'
    'casterly-rock'
    'lannisport'
    'kings-landing'
    'kingswood'
    'blackwater-bay'
    'dragonstone'
    'highgarden'
    'storms-end'
  ]

  expanded: false
  loading: false # when box control request is happening
  loadingPublicKey: false # when loading public key from server
  addingPublicKeyToGitHub: false # when adding public key to github

  vmem_multiplier: (-> # no camel case to be consistent with other properties
    @_formatMemoryMultiplier(@get('virtual_memory'), @get('memory'))
  ).property 'virtual_memory', 'memory'

  expected_vmem_multiplier: (-> # no camel case to be consistent with other properties
    @_formatMemoryMultiplier(@get('expected_virtual_memory'), @get('memory'))
  ).property 'virtual_memory', 'memory'

  hasBaseCPUShare: (->
    parseInt(@get('cpu_multiplier'), 10) == 1
  ).property 'cpu_multiplier'

  requiresCPUShareDowngrade: (->
    @get('expected_cpu_multiplier') < @get('cpu_multiplier')
  ).property 'cpu_multiplier', 'expected_cpu_multiplier'

  requiresCPUShareUpgrade: (->
    @get('expected_cpu_multiplier') > @get('cpu_multiplier')
  ).property 'cpu_multiplier', 'expected_cpu_multiplier'

  requiresVirtualMemoryDowngrade: (->
    @get('expected_virtual_memory') < @get('virtual_memory')
  ).property 'virtual_memory', 'expected_virtual_memory'

  requiresVirtualMemoryUpgrade: (->
    @get('expected_virtual_memory') > @get('virtual_memory')
  ).property 'virtual_memory', 'expected_virtual_memory'

  requiresDowngrade: (->
    @get('requiresCPUShareDowngrade') || @get('requiresVirtualMemoryDowngrade')
  ).property 'requiresCPUShareDowngrade', 'requiresVirtualMemoryDowngrade'

  requiresUpgrade: (->
    @get('requiresCPUShareUpgrade') || @get('requiresVirtualMemoryUpgrade')
  ).property 'requiresCPUShareUpgrade', 'requiresVirtualMemoryUpgrade'

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
    AIO.Region.findById @get('region_id')
  ).property 'region_id'

  boxTemplate: (->
    AIO.BoxTemplate.findById @get('box_template_id')
  ).property 'box_template_id'

  sourceSnapshot: (->
    AIO.get('router.snapshotsController').findById @get('source_snapshot_id')
  ).property 'source_snapshot_id'

  snapshots: (->
    AIO.SnapshotsCollection.create
      content: _.filter AIO.get('router.snapshotsController').get('content'), (snapshot) =>
        @get('id') == snapshot.get('box_id')
  ).property 'AIO.router.snapshotsController.content'

  snapshottable: (->
    @get('state') == 'stopped'
  ).property 'state'

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

  snapshotting: (->
    @get('state') == 'snapshotting'
  ).property 'state'

  failed: (->
    @get('state') == 'failed'
  ).property 'state'

  working: (->
    !(_.include(['stopped', 'running', 'terminated', 'provisioning', 'failed'], @get('state')))
  ).property 'state'

  underMaintenance: (->
    @get('state') == "migrating" || !@get('region.enabled')
  ).property 'state', 'region.enabled'

  stateForOrb: (->
    if @get 'underMaintenance'
      'under_maintenance'
    else
      @get 'state'
  ).property 'state', 'underMaintenance'

  stateForDisplay: (->
    switch state = @get 'state'
      when 'failed'
        'provisioning failed'
      when 'changing_specs'
        'changing specs'
      else
        state
  ).property 'state'

  customDomainPreviewable: (->
    @get('custom_domains_allowed') && @get('custom_domain')
  ).property 'custom_domains_allowed', 'custom_domain'

  randomName: ->
    random = AIO.util.randomElement(@randomNames)

    if suffix = @get('boxTemplate.runtime')
      "#{random}-#{suffix}"
    else
      random

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

  fetchBoxInfo: ->
    $.ajax
      type: 'GET'
      dataType: 'json'
      url: "#{@get 'resourceUrl'}/#{@get 'id'}/info"

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

  updateAuth: (cb) ->
    @set 'loading', true
    data = box:
      auth_username: @get('auth_username')
      auth_password: @get('auth_password')
    $.ajax(
      type: 'PUT'
      dataType: 'json'
      data: data
      url: "#{@get 'resourceUrl'}/#{@get 'id'}/auth"
    ).always(=>
      @set 'loading', false
    ).done (json) =>
      json = json[@get 'resourceName']
      @deserialize json
      cb(null)
    .fail (e) =>
      if e.status == 422
        errors = @get 'errors' || {}
        errors = $.parseJSON(e.responseText).errors
        @set 'errors', errors
        cb(new Error(errors))

  updateCustomDomain: (cb) ->
    @set 'loading', true
    data = box:
      custom_domain: @get('custom_domain')
    $.ajax(
      type: 'PUT'
      dataType: 'json'
      data: data
      url: "#{@get 'resourceUrl'}/#{@get 'id'}/custom_domain"
    ).always(=>
      @set 'loading', false
    ).done (json) =>
      json = json[@get 'resourceName']
      @deserialize json
      cb(null)
    .fail (e) =>
      if e.status == 422
        errors = @get 'errors' || {}
        errors = $.parseJSON(e.responseText).errors
        @set 'errors', errors
        cb(new Error(errors))

  _formatMemoryMultiplier: (number, base) ->
    if number % base == 0
      number / base
    else
      parseFloat((number / base).toFixed(1))
