AIO.ResourceController = Em.ResourceController.extend
  findResource: (id, callback) ->
    if resource = this.findById id
      callback resource
    else
      resource = @get('resourceType').create id: id
    resource.findResource().done =>
      if !this.get('content') || this.get('content').length == 0
        this.set 'content', []
      if this.indexOf(resource) == -1
        this.addObject resource
      callback resource

