AIO.BoxesNewController = Em.ObjectController.extend
  boxNamePlaceholder: 'my-awesome-box'
  isIntro: false
  closestRegionId: null
  boxNameIsDirty: false # true if user has changed box name herself

  closestRegionIdDidChange: (->
    this.preselectRegion()
  ).observes 'closestRegionId'

  boxTemplateIdDidChange: (->
    @set 'name', @get('content').randomName() unless @boxNameIsDirty
  ).observes 'content.box_template_id'

  newRecord: ->
    box = AIO.Box.create()
    @set 'content', box
    box.set 'box_template_id', AIO.get('router.boxTemplatesController.firstObject.id')
    this.preselectRegion()

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done =>
        AIO.get('router.boxesController').addObject record

        page = 'boxes.provisioning'
        page = 'intro.n2o' if @get 'isIntro'

        AIO.get('router').transitionTo page, id: record.get 'id'
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'

  preselectRegion: ->
    box = @get 'content'
    return if box.get 'region_id' # Don't interfere with user's selection.
    if regionId = @get 'closestRegionId'
      box.set 'region_id', regionId
      return
    AIO.Region.fetchClosestRegion()
