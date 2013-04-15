AIO.ResourceController = Em.ResourceController.extend
  # Override Ember content alias to model so it plays nice with ember-rest.
  # This solves some cases when ember reset the model to undefined context
  # while trying to setup the controller.
  model: null

  findResource: (id, callback) ->
    if resource = this.findById id
      callback resource
    else
      resource = @get('resourceType').create id: id
    resource.findResource().done =>
      if this.indexOf(resource) == -1
        this.addObject resource
      callback resource

