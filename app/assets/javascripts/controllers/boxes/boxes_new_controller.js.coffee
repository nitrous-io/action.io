AIO.BoxesNewController = Em.ObjectController.extend
  boxNamePlaceholder: 'my-awesome-box'
  isLightningMode: false

  preselectRegion: ->
    AIO.Region.closestRegion (err, region) =>
      box = @get 'content'
      box.set 'region_id', region?.id unless box.region_id

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
        page = 'lightning.github' if @get 'isLightningMode'

        AIO.get('router').transitionTo page, id: record.get 'id'
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
