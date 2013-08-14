AIO.BoxesNewController = Em.ObjectController.extend
  newRecord: ->
    box = AIO.Box.create()
    box.set 'box_template_id', AIO.get('router.boxTemplatesController.firstObject.id')
    @set 'content', box

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done ->
        AIO.get('router.boxesController').addObject record
        AIO.get('router').transitionTo 'boxes.provisioning', id: record.get 'id'
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
