App.ResourceController = Em.ResourceController.extend
  findResource: (id, callback) ->
    if resource = this.findById id
      callback resource
    else
      resource = @get('resourceType').create id: id
    resource.findResource().done =>
      if this.indexOf(resource) == -1
        this.addObject resource
      callback resource

