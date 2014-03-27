AIO.BaseModel = klass = Em.Model.extend AIO.Validatable,
  id: Em.attr()
  saving: Em.computed.alias 'isSaving'

  makeRequest: (action, method='GET', params) ->
    @constructor.adapter?.makeRequest? this, action, method, params

  loadHash: (hash) ->
    @load hash[Em.get @constructor, 'primaryKey'], hash

  save: ->
    promise = @_super()
    promise.then undefined, (e) =>
      if e.status == 422 && e.responseText
        @set 'errors', JSON.parse(e.responseText).errors
      @set 'isSaving', false
    promise

klass.reopenClass
  adapter: AIO.RESTAdapter.create()
  camelizeKeys: false # too much work

  all: ->
    @_findAllRecordArray ?= Em.RecordArray.create(modelClass: this, content: Em.A())

  preload: (hashes) ->
    recordArray = @all()
    recordArray.load this, hashes
    recordArray
