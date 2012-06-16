BackboneAdditions =
  Collection:
    # fetch and update collection using add/remove instead of reset
    aio_fetch: (options={}) ->
      tempCollection = new @constructor
      tempCollection.model = @model
      tempCollection.url = @url
      success = options.success
      options.success = (tempCollection, response) =>
        currentModels = @models
        fetchedModels = tempCollection.models
        removedModels = _.difference(currentModels, fetchedModels)
        this.add(m.toJSON() for m in fetchedModels)
        this.remove(removedModels)
        tempCollection.reset()
        success?(this, response)
      tempCollection.fetch(options)

for klass, mixin of BackboneAdditions
  _.extend(Backbone[klass].prototype, mixin)

