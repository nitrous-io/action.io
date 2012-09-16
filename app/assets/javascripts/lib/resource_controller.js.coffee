AIO.ResourceController = Em.ResourceController.extend
  findResource: (id) ->
    resource = this.findById(id) || @get('resourceType').create id: id
    resource.findResource().pipe(->
      resource
    ).done =>
      if this.indexOf(resource) == -1
        this.addObject resource

