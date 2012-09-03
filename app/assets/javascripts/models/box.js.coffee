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

