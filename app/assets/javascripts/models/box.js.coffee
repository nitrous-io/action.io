class aio.models.Box extends Backbone.Model
  region: ->
    aio.app.regions.get(this.get('region_id'))

  boxTemplate: ->
    aio.app.boxTemplates.get(this.get('box_template_id'))

class aio.collections.Boxes extends Backbone.Collection
  model: aio.models.Box
  url: '/boxes'

