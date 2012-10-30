AIO.Box = AIO.Resource.extend
  name             : null
  host             : null
  state            : null
  box_template_id  : null
  owner_id         : null
  region_id        : null
  port             : null
  box_server_uri   : null

  resourceUrl: '/boxes'
  resourceName: 'box'
  resourceProperties: ['name', 'region_id', 'box_template_id']

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0
    region_id: (v) -> "needs to be selected" unless v
    box_template_id: (v) -> "needs to be selected" unless v

  expanded: false
  loading: false # when box control request is happening

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

