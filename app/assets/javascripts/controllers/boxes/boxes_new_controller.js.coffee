AIO.BoxesNewController = Em.ObjectController.extend
  needs: ['boxTemplates', 'regions', 'boxes']

  newRecord: ->
    box = AIO.Box.create()
    box.set 'box_template_id', @get('controllers.boxTemplates.firstObject.id')
    @set 'content', box

  save: ->
    record = @get 'content'
    boxes = @get 'controllers.boxes'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done =>
        boxes.addObject record
        @transitionToRoute 'boxes.provisioning', record
      .always ->
        record.set 'saving', false

  cancel: ->
    @transitionToRoute 'boxes.index'
