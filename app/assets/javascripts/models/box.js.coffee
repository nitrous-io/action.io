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
  resourceProperties: ['name', 'region_id']

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0

  expanded: false

  sshURI: (->
    host = @get('host')
    port = @get('port')
    if host && port
      "ssh://#{@get('host')}:#{@get('port')}"
  ).property 'host', 'port'

  region: (->
    AIO.get('router.regionsController.content').findProperty('id', @get('region_id'))
  ).property 'region_id'

  stopped: (->
    @get('state') == 'stopped'
  ).property 'state'

  running: (->
    @get('state') == 'running'
  ).property 'state'

  suspended: (->
    @get('state') == 'suspended'
  ).property 'state'

  terminated: (->
    @get('state') == 'terminated'
  ).property 'state'

  working: (->
    !(_.include(['stopped', 'running', 'suspended', 'terminated'], @get('state')))
  ).property 'state'

