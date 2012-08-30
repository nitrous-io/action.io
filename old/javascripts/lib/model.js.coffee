class AIO.Model extends Backbone.RelationalModel
  constructor: ->
    super
    this.set(errors: null)

  save: (attributes, options={}) ->
    this.set(errors: null)
    _.defaults(options, wait: true)
    errorCallback = options.error
    options.error = (model, response) =>
      if response.status == 422 && response.responseText.match(/"errors":{/)
        this.set(errors: JSON.parse(response.responseText).errors)
      errorCallback?(model, response)
    super(attributes, options)

AIO.Model._setup = AIO.Model.setup
AIO.Model.setup = (collectionName=null) ->
  this._setup()
  AIO.c ||= {}
  collection = Backbone.Relational.store.getCollection(this)
  collection.url = this::urlRoot
  if collectionName
    AIO.c[collectionName] = collection

