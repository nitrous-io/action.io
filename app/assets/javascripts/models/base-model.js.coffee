AIO.BaseModel = klass = Em.Model.extend
  id: Em.attr()

  makeRequest: (action, method='GET', params) ->
    @constructor.adapter?.makeRequest? this, action, method, params

  loadHash: (hash) ->
    @load hash[Em.get @constructor, 'primaryKey'], hash

klass.reopenClass
  adapter: AIO.RESTAdapter.create()
  camelizeKeys: false # too much work

  all: ->
    @_findAllRecordArray ?= Em.RecordArray.create(modelClass: this)

  preload: (hashes) ->
    recordArray = @all()
    recordArray.load this, hashes
    recordArray
