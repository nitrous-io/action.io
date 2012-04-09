aio.models ||= {}
aio.collections ||= {}

class aio.models.Box extends Backbone.Model
  url: '/boxes'

  defaults:
    name: null
    region: null
    host: null
    port: null
    status: null
    box_template_id: null

class aio.collections.Boxes extends Backbone.Collection
  model: aio.models.Box
  url: '/boxes'

