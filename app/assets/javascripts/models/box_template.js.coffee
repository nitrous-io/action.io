class aio.models.BoxTemplate extends Backbone.Model
  url: '/box_templates'

  defaults:
    name: null
    image: null
    description: null

class aio.collections.BoxTemplates extends Backbone.Collection
  model: aio.models.BoxTemplate
  url: '/box_templates'

