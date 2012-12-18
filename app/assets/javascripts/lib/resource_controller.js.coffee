AIO.ResourceController = Em.ResourceController.extend
  findResource: (id, callback) ->
    if resource = this.findById id
      callback resource
    else
      resource = @get('resourceType').create id: id
    resource.findResource().done =>
      if this.indexOf(resource) == -1
        this.addObject resource
      callback resource

  # Given a json response, build a `ResourceType` object but does not insert it
  # into content, we will manually manage the insertion.
  build: (json) -> @get('resourceType').create().deserialize(json)

  # Given a list of json objects, build a list of `ResourceType` objects but
  # does not insert it into contents. This is helpful when we want to preload
  # the data, but doesnt want to display the data somehow until some event is
  # ready.
  buildAll: (jsonList) -> (@build(json) for json in jsonList[@get('jsonRoot')])

  # Given a list of resources, push them into contents. We will not insert
  # duplicated resources, but update them instead. We will also remove
  # resources that is not in the new resource list
  loadResources: (resources) ->
    @propertyWillChange('content')
    Ember.beginPropertyChanges()

    # update
    for resource in resources
      if (existingResource = @findProperty('id', resource.get("id")))
        @removeObject existingResource
      @addObject resource

    # remove
    @forEach (resource, i, list) ->
      unless (resources.findProperty('id', resource.id))
        list.removeObject resource

    Ember.endPropertyChanges()
    @propertyDidChange('content')
    return this
