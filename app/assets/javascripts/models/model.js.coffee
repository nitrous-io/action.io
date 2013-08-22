# AIO.Model
# =========
# Minimal implementation of promise based model without stuffs that we dont
# need (relations etc...)

# our custom ajax to return a rsvp promise instead of normal jquery promise
customAjax = (url, params, method) ->
  settings = type: method, dataType: "json"
  return Em.Deferred.promise (promise) ->
    if params
      if method == "GET"
        settings.data = params
      else
        settings.contentType = "application/json; charset=utf-8"
        settings.data = JSON.stringify params
    settings.success = (xhr) -> Em.run promise, promise.resolve, xhr
    settings.error = (xhr, textStatus, errorThrown) -> promise.reject xhr
    Ember.$.ajax url, settings

AIO.Model = Em.Object.extend
  isLoading: false

  # set attributes of the model using the provided json structure
  deserialize: (json) ->
    Em.beginPropertyChanges()
    this.set key, value for own key, value of json
    Ember.endPropertyChanges()
    return this

# hold a record of array, 
AIO.RecordArray = Em.ArrayProxy.extend
  isLoading: false
  content: null

  # deserialize a series of json data by a given namespace
  deserialize: (klass, namespace, json) ->
    # notify that the content will probably changed
    this.propertyWillChange 'content'
    Ember.beginPropertyChanges()

    # updated is the latest data from server
    updated = []

    # add all new data
    json = json[namespace] if namespace
    json.forEach (data) =>
      if model = this.findProperty('id', data['id'])
        model.deserialize(data)
      else
        model = klass.create()
        model.deserialize(data)
        this.addObject model
      updated.push data['id']

    # cleanup old data that has been deleted
    this.forEach (resource, index, list) ->
      if updated.indexOf(resource.get('id')) == -1
        list.removeObject resource

    # notify that we have finished
    Ember.endPropertyChanges()
    this.propertyDidChange 'content'
    return this

# use similar API to ember-rest to ease migration path, but instead of using
# callback, we return a promise as that what Ember said
AIO.Model.reopenClass
  # find a single resource given an id
  findResource: (id) ->
    model = this.findCache(id)
    # not in cache, create a new one
    model = this.create() unless model
    # perform an ajax request to update the model data
    model.set 'isLoading', true
    this.ajax(this.buildURL(id)).then (json) ->
      model.deserialize(json)
      model.set 'isLoading', false
    # meanwhile, return the loading model
    this.addModel model
    return model

  # alias for findResource
  findById: (id) -> this.findResource id

  # refresh all data from servers
  # return an instance of AIO.RecordArray which content will be filled when the
  # request finishes
  findAll: () ->
    throw new Error('`jsonRoot` is missing') unless this.jsonRoot
    this._data = AIO.RecordArray.create(content: []) unless this._data
    this._data.set 'isLoading', true
    this.ajax(this.buildURL()).then (json) =>
      this._data.deserialize this, this.jsonRoot, json
      this._data.set 'isLoading', false
    return this._data

  # preload all models to cache. This will clear all existing data
  # cache object by id so we can retrieve it later
  loadAll: (hashes) ->
    this._data = AIO.RecordArray.create(content: []) unless this._data
    this._data.clear()
    this._data.deserialize this, null, hashes
    return this

  # find the model in cache by its id
  findCache: (id) ->
    return unless this._data
    this._data.findProperty('id', id)

  addModel: (model) ->
    this._data = AIO.RecordArray.create(content: []) unless this._data
    this._data.addObject model

  removeModel: (model) ->
    this._data = AIO.RecordArray.create(content: []) unless this._data
    this._data.removeObject model

  buildURL: (id) ->
    urlRoot = this.resourceUrl
    throw new Error('`resourceUrl` is missing') unless urlRoot
    if id
      urlRoot + "/" + id + ".json"
    else
      urlRoot + ".json"

  # shorthand to customAjax so we dont need to specify unused values
  ajax: (url, params, method) ->
    if arguments.length == 1
      return customAjax url, {}, "GET"
    else
      return customAjax url, params, method || "GET"

# test
# AIO.BoxTest = AIO.Model.extend()
# AIO.BoxTest.resourceName = 'box'
# AIO.BoxTest.resourceUrl = '/boxes'
# AIO.BoxTest.jsonRoot = 'boxes'
