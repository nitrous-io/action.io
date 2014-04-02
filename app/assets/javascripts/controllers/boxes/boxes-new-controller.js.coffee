App.BoxesNewController = Em.ObjectController.extend
  boxNamePlaceholder: 'my-awesome-box'
  isIntro: false
  closestRegionId: null
  boxNameIsDirty: false # true if user has changed box name herself

  closestRegionIdDidChange: (->
    @preselectRegion()
  ).observes 'closestRegionId'

  boxTemplateIdDidChange: (->
    return unless box = @get 'content'
    return if @get('boxNameIsDirty')
    randomName = box.randomName()

    if existingBox = App.get('boxes').findProperty 'name', randomName
      randomName = "#{randomName}-1"

    @set 'name', randomName
  ).observes 'content.box_template_id'

  boxTemplateSelected: (->
    box = @get 'content'
    if box.get 'box_template_id'
      box.set 'source_snapshot_id', null
  ).observes 'content.box_template_id'

  sourceSnapshotSelected: (->
    box = @get 'content'
    if box.get 'source_snapshot_id'
      box.set 'box_template_id', null
    else
      box.set 'box_template_id', App.BoxTemplate.all().get('firstObject.id')
  ).observes 'content.source_snapshot_id'

  newRecord: ->
    @set 'content', box = App.Box.create()
    box.set 'box_template_id', App.BoxTemplate.all().get('firstObject.id')
    @preselectRegion()

  save: ->
    record = @get 'content'
    record.save().then =>
      page = 'boxes.provisioning'
      page = 'intro.n2o' if @get 'isIntro'

      App.get('router').transitionTo page, id: record.get 'id'

  cancel: ->
    App.get('router').transitionTo 'boxes.index'

  preselectRegion: ->
    box = @get 'content'
    return if box.get 'region_id' # Don't interfere with user's selection.
    if regionId = @get 'closestRegionId'
      box.set 'region_id', regionId
      return
    App.Region.fetchClosestRegion()
