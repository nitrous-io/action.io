class aio.models.PublicKey extends Backbone.Model

class aio.collections.PublicKeys extends Backbone.Collection
  model: aio.models.PublicKey
  url: '/public_keys'

