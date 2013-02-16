AIO.RESTAdapter = DS.RESTAdapter.extend
  rootForType: (type, includeParent=false) ->
    serializer = Em.get(this, 'serializer')
    roots = []
    if (parentResource = type.parentResource) && includeParent
      parentRoot = this.rootForType(parentResource.constructor)
      roots.push serializer.pluralize(parentRoot)
      roots.push parentResource.get('id')
    roots.push serializer.rootForType(type)
    roots.join('/')

  createRecord: (store, type, record) ->
    root = this.rootForType(type, true)
    data = {}
    data[root] = this.serialize(record, includeId: true)
    this.ajax this.buildURL(root), "POST",
      data: data
      context: this
      success: (json) ->
        Ember.run this, -> this.didCreateRecord store, type, record, json
      error: (xhr) ->
        this.didError store, type, record, xhr

  deleteRecord: (store, type, record) ->
    id = Em.get(record, "id")
    root = this.rootForType(type, true)
    this.ajax this.buildURL(root, id), "DELETE",
      context: this
      success: (json) ->
        Ember.run this, -> this.didSaveRecord store, type, record, json

  find: (store, type, id) ->
    root = @rootForType(type, true)
    this.ajax this.buildURL(root, id), "GET",
      success: (json) ->
        Ember.run this, -> this.didFindRecord store, type, json, id

  findAll: (store, type, since) ->
    root = this.rootForType(type, true)
    this.ajax this.buildURL(root), "GET",
      data: @sinceQuery(since)
      success: (json) ->
        Ember.run this, -> this.didFindAll store, type, json

DS.JSONSerializer.reopen
  pluralize: (string) ->
    return 'boxes' if string == 'box'
    @_super(string)

AIO.Store = DS.Store.extend
  revision: 11
  adapter: AIO.RESTAdapter.create()
    
AIO.buildNestedResource = (parent, model) ->
  newModel = model.extend()
  newModel.reopenClass
    parentResource: parent
    toString: -> model.toString()
  newModel
