AIO.BoxesNewController = Em.ObjectController.extend
  boxNamePlaceholder: 'my-awesome-box'
  isIntro: false
  closestRegionId: null

  preselectRegion: ->
    box = @get 'content'
    return if box.region_id

    if @closestRegionId
      box.set 'region_id', @closestRegionId
    else
      AIO.Region.closestRegion (err, region) =>
        box.set 'region_id', region?.id unless box.region_id
        @set 'closestRegionId', region?.id

  newRecord: ->
    box = AIO.Box.create()
    box.set 'box_template_id', AIO.get('router.boxTemplatesController.firstObject.id')
    @set 'content', box
    @set 'boxNamePlaceholder', AIO.util.randomBoxName()
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
        page = 'intro.n2o' if @isIntro

        AIO.get('router').transitionTo page, id: record.get 'id'
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
