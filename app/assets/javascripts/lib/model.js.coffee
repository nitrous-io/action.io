class AIO.Model extends Backbone.RelationalModel

AIO.Model._setup = AIO.Model.setup
AIO.Model.setup = (collectionName=null) ->
  this._setup()
  AIO.c ||= {}
  collection = Backbone.Relational.store.getCollection(this)
  collection.url = this::urlRoot
  if collectionName
    AIO.c[collectionName] = collection

