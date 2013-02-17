AIO.BoxesNewController = Em.ObjectController.extend
  needs: ['boxTemplates', 'regions', 'boxes']

  newRecord: ->
    box = AIO.Box.create()
    box.set 'box_template_id', @get('controllers.boxTemplates.firstObject.id')
    @set 'content', box

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done =>
        debugger
        @get('controllers.boxes').addObject record
        this.transitionToRoute 'boxes.provisioning', id: record.get 'id'
      .always ->
        record.set 'saving', false

  cancel: ->
    this.transitionToRoute 'boxes.index'
